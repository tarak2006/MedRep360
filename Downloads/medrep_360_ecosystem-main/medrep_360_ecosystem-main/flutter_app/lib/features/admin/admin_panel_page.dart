import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:html' as html;
import '../../widgets/sidebar.dart';

// ─── Base URLs ───────────────────────────────────────────────────────────────
// The Node.js backend (leads, doctors, interactions)
const String _nodeBaseUrl = kReleaseMode
    ? 'https://medrep360-backend-599554914298.asia-south1.run.app/api'
    : 'http://localhost:5000/api';

// Dedicated Python FastAPI ingestion server (medrep_360 repo)
final String _ingestUrl = kReleaseMode
    ? 'https://medrep360-599554914298.asia-south1.run.app/api/ingest/file'
    : 'http://localhost:8080/api/ingest/file';

// The FastAPI / MedRep360 AI pipeline backend (data ingestion)
const String _aiBaseUrl = kReleaseMode
    ? 'https://medrep360-ai-599554914298.asia-south1.run.app' // update with your production AI URL
    : 'http://localhost:8080';

// ─── Upload history entry ────────────────────────────────────────────────────
class _UploadRecord {
  final String filename;
  final DateTime timestamp;
  String status; // 'Uploading', 'Success', 'Failed'
  String? message;

  _UploadRecord({
    required this.filename,
    required this.timestamp,
    this.status = 'Uploading',
    this.message,
  });
}

// ─── Page ────────────────────────────────────────────────────────────────────
class AdminPanelPage extends StatefulWidget {
  const AdminPanelPage({super.key});

  @override
  State<AdminPanelPage> createState() => _AdminPanelPageState();
}

class _AdminPanelPageState extends State<AdminPanelPage> {
  final List<_UploadRecord> _uploads = [];
  bool _isUploading = false;

  // Ingestion pipeline status
  bool? _pipelineConnected;
  String _qdrantCollection = '';

  @override
  void initState() {
    super.initState();
    _checkPipelineStatus();
  }

  // ── Check AI pipeline status ───────────────────────────────────────────────
  Future<void> _checkPipelineStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$_aiBaseUrl/api/ingest/status'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        setState(() {
          _pipelineConnected = body['qdrant_connected'] == true;
          _qdrantCollection = body['qdrant_collection'] ?? '';
        });
      } else {
        setState(() => _pipelineConnected = false);
      }
    } catch (_) {
      setState(() => _pipelineConnected = false);
    }
  }

  // ── Pick & upload ──────────────────────────────────────────────────────────
  // Sends the file to the FastAPI MedRep360 AI pipeline at:
  //   POST http://localhost:8080/api/ingest/file
  // Required form fields: brand_id (string), file (multipart)
  void _pickAndUploadFile() {
    // Web file picker via dart:html
    final uploadInput = html.FileUploadInputElement();
    // The AI pipeline supports: PDF, DOCX, TXT, CSV, XLSX
    uploadInput.accept = '.pdf,.docx,.txt,.csv,.xlsx,.xls';
    uploadInput.click();

    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;

      final filename = file.name;
      final record = _UploadRecord(
        filename: filename,
        timestamp: DateTime.now(),
        status: 'Uploading',
      );

      setState(() {
        _isUploading = true;
        _uploads.insert(0, record);
      });

      try {
        final reader = html.FileReader();
        reader.readAsArrayBuffer(file);
        await reader.onLoad.first;

        final bytes = reader.result as Uint8List;

        // ✅ Correct endpoint: FastAPI AI pipeline (port 8080), NOT Node.js (port 5000)
        final request = http.MultipartRequest(
          'POST',
          Uri.parse(_ingestUrl),
        );

        // Required form fields for /api/ingest/file
        request.fields['brand_id'] = 'brand_default';
        request.fields['strategy'] = 'auto';
        request.fields['chunking_strategy'] = 'by_title';

        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: filename,
          ),
        );

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);

        setState(() {
          _isUploading = false;
          // API returns 202 Accepted (queued for background processing)
          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 202) {
            record.status = 'Success';
            try {
              final body = json.decode(response.body);
              final msg = body['message'] ?? 'Queued for ingestion';
              final gcsUri = body['gcs_uri'] ?? '';
              record.message = gcsUri.isNotEmpty ? '$msg\n📦 $gcsUri' : msg;
            } catch (_) {
              record.message = 'File queued for ingestion successfully';
            }
          } else {
            record.status = 'Failed';
            record.message = 'Server error (${response.statusCode})';
          }
        });
      } catch (e) {
        setState(() {
          _isUploading = false;
          record.status = 'Failed';
          record.message = 'Upload failed: ${e.toString()}';
        });
      }
    });
  }

  // ── Status colour & icon ───────────────────────────────────────────────────
  Color _statusColor(String status) {
    switch (status) {
      case 'Success':
        return const Color(0xFF00C896);
      case 'Failed':
        return const Color(0xFFFF4D6D);
      default:
        return const Color(0xFFFFB347);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Success':
        return Icons.check_circle_rounded;
      case 'Failed':
        return Icons.error_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const Sidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero header ───────────────────────────────────────────────
            _buildHeroHeader(),
            const SizedBox(height: 16),

            // ── Pipeline status banner ────────────────────────────────────
            _buildPipelineStatusBanner(),
            const SizedBox(height: 20),

            // ── Data Ingestion card ───────────────────────────────────────
            _buildIngestionCard(),
            const SizedBox(height: 32),

            // ── Upload status history ─────────────────────────────────────
            const Text(
              'Upload Status History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A237E),
              ),
            ),
            const SizedBox(height: 12),
            _buildUploadHistory(),
          ].animate(interval: 80.ms).fade(duration: 400.ms).slideY(begin: 0.08),
        ),
      ),
    );
  }

  // ── Hero header widget ─────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF3949AB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A237E).withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
              size: 40,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.06, 1.06),
                  duration: 1400.ms,
                  curve: Curves.easeInOut)
              .shimmer(duration: 2800.ms, color: Colors.white24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Admin Control Centre',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage data pipelines, ingest bulk records, and monitor upload activity.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Pipeline status banner ─────────────────────────────────────────────────
  Widget _buildPipelineStatusBanner() {
    final bool? connected = _pipelineConnected;
    final Color color = connected == null
        ? Colors.orange
        : connected
            ? const Color(0xFF00C896)
            : const Color(0xFFFF4D6D);
    final IconData icon = connected == null
        ? Icons.sync_rounded
        : connected
            ? Icons.check_circle_rounded
            : Icons.error_rounded;
    final String label = connected == null
        ? 'Checking AI pipeline status…'
        : connected
            ? 'AI Pipeline Connected  •  Collection: $_qdrantCollection'
            : 'AI Pipeline Offline — start the MedRep360 server on port 8080';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: color, size: 18),
            tooltip: 'Refresh status',
            onPressed: _checkPipelineStatus,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ── Data ingestion card ────────────────────────────────────────────────────
  Widget _buildIngestionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF3949AB).withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3949AB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cloud_upload_rounded,
                  color: Color(0xFF3949AB),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Ingestion Pipeline',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A237E),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Upload PDF, DOCX, CSV or Excel files to feed the AI agent',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Dashed upload zone ──────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3949AB).withOpacity(0.35),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.upload_file_rounded,
                  size: 52,
                  color: const Color(0xFF3949AB).withOpacity(0.6),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Supported formats: PDF, DOCX, TXT, CSV, XLSX, XLS',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),

                // ── Upload button ─────────────────────────────────────────
                _isUploading
                    ? Column(
                        children: [
                          const SizedBox(
                            width: 36,
                            height: 36,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              color: Color(0xFF3949AB),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Uploading…',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        onPressed: _pickAndUploadFile,
                        icon: const Icon(Icons.cloud_upload_rounded, size: 22),
                        label: const Text(
                          'Upload Data File for Ingestion',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3949AB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor:
                              const Color(0xFF3949AB).withOpacity(0.4),
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                        .shimmer(
                          duration: 2200.ms,
                          color: Colors.white24,
                          angle: 0.5,
                        ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Info chips ─────────────────────────────────────────────────
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoBadge(Icons.cloud_rounded, 'Sends to: localhost:8080/api/ingest/file'),
              _infoBadge(Icons.label_rounded, 'brand_id: brand_default (auto-set)'),
              _infoBadge(Icons.info_outline_rounded,
                  'CSV: name, specialty, region, mobile, email'),
              _infoBadge(Icons.info_outline_rounded,
                  'PDF / DOCX: product brochures, clinical data'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF3949AB)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF3949AB),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload history list ────────────────────────────────────────────────────
  Widget _buildUploadHistory() {
    if (_uploads.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.history_toggle_off_rounded,
                size: 48, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              'No uploads yet. Upload a file to get started.',
              style: TextStyle(color: Colors.grey[500], fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _uploads.length,
        separatorBuilder: (_, __) =>
            Divider(height: 1, color: Colors.grey[100]),
        itemBuilder: (context, index) {
          final record = _uploads[index];
          final color = _statusColor(record.status);
          return ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon(record.status), color: color, size: 22),
            ),
            title: Text(
              record.filename,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                record.message ?? record.status,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(record.timestamp),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
          ).animate().fade(duration: 350.ms, delay: (40 * index).ms).slideY(begin: 0.1);
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    final d = '${local.day}/${local.month}/${local.year}';
    return '$d  $h:$m';
  }
}
