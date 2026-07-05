import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/dashboard_card.dart';
import '../../models/interaction.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../../services/session_state.dart';
import '../../theme_config.dart';

class InteractionsPage extends StatefulWidget {
  const InteractionsPage({super.key});

  @override
  State<InteractionsPage> createState() => _InteractionsPageState();
}

class _InteractionsPageState extends State<InteractionsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Interaction> _interactions = [];
  List<Doctor> _doctors = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.fetchInteractions(),
        _apiService.fetchDoctors(),
      ]);
      setState(() {
        _interactions = futures[0] as List<Interaction>;
        _doctors = futures[1] as List<Doctor>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getDoctorName(String doctorId) {
    final doc = _doctors.where((d) => d.id == doctorId).firstOrNull;
    return doc?.name ?? 'Unknown Doctor';
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'in-person':
        return const Color(0xFF0D9488); // Teal
      case 'virtual':
        return const Color(0xFF2563EB); // Blue
      case 'phone':
        return const Color(0xFFEA580C); // Orange
      case 'email':
        return const Color(0xFF4F46E5); // Indigo
      default:
        return const Color(0xFF64748B); // Slate
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'in-person':
        return Icons.people_outline_rounded;
      case 'virtual':
        return Icons.videocam_outlined;
      case 'phone':
        return Icons.phone_callback_rounded;
      case 'email':
        return Icons.alternate_email_rounded;
      default:
        return Icons.chat_bubble_outline;
    }
  }

  void _showAddInteractionDialog() {
    if (_doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doctors available. Add a doctor first!')),
      );
      return;
    }

    String? selectedDoctorId = _doctors.first.id;
    String selectedType = 'In-person';
    final notesController = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Log New Interaction',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF1F5F9)),
                    const SizedBox(height: 16),
                    
                    // Doctor selection
                    const Text(
                      'Select Target Doctor *',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedDoctorId,
                          isExpanded: true,
                          items: _doctors.map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc.id,
                              child: Text('${doc.name} (${doc.specialty})'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedDoctorId = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Show doctor availability inline
                    Builder(
                      builder: (context) {
                        final selectedDoc = _doctors.firstWhere((d) => d.id == selectedDoctorId, orElse: () => _doctors.first);
                        final String availabilityText = (selectedDoc.availableFrom.isNotEmpty && selectedDoc.availableTo.isNotEmpty)
                            ? 'Preferred Sync window: ${selectedDoc.availableFrom} to ${selectedDoc.availableTo}'
                            : 'Preferred Sync window: Not specified (Available anytime)';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  availabilityText,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // Type selection
                    const Text(
                      'Interaction Channel Type *',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF8FAFC),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedType,
                          isExpanded: true,
                          items: ['In-person', 'Virtual', 'Phone', 'Email'].map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedType = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Date & Time Picker Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interaction Date *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2025),
                                    lastDate: DateTime(2030),
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 13)),
                                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Interaction Time *',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                              ),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedTime,
                                  );
                                  if (picked != null) {
                                    setModalState(() => selectedTime = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(12),
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(selectedTime.format(context), style: const TextStyle(fontSize: 13)),
                                      const Icon(Icons.access_time_rounded, color: Color(0xFF64748B), size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Notes input
                    const Text(
                      'Discussion / Summary Notes *',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'What details did you establish during this clinical interaction?',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E3A8A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (notesController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter notes first.')),
                            );
                            return;
                          }

                          final selectedDoc = _doctors.firstWhere((d) => d.id == selectedDoctorId, orElse: () => _doctors.first);
                          if (selectedDoc.availableFrom.isNotEmpty && selectedDoc.availableTo.isNotEmpty) {
                            final startTime = _parseTimeString(selectedDoc.availableFrom);
                            final endTime = _parseTimeString(selectedDoc.availableTo);
                            if (startTime != null && endTime != null) {
                              if (!_isTimeBetween(selectedTime, startTime, endTime)) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                                        SizedBox(width: 10),
                                        Text('Outside Doctor Hours'),
                                      ],
                                    ),
                                    content: Text('${selectedDoc.name} is only available from ${selectedDoc.availableFrom} until ${selectedDoc.availableTo}.\n\nSelected time: ${selectedTime.format(context)} is outside of their working hours. Please change the time.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Adjust Time', style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }
                            }
                          }

                          Navigator.pop(context);
                          setState(() => _isLoading = true);

                          final combinedDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime.hour,
                            selectedTime.minute,
                          );

                          final newInteractionMap = {
                            'doctor': selectedDoctorId,
                            'type': selectedType,
                            'notes': notesController.text.trim(),
                            'date': combinedDateTime.toIso8601String(),
                          };

                          final result = await _apiService.createInteraction(newInteractionMap);
                          if (result != null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Interaction logged successfully!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } else {
                            // If backend offline
                            final tempDocName = _getDoctorName(selectedDoctorId!);
                            final localMock = Interaction(
                              id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                              doctorId: selectedDoctorId!,
                              doctorName: tempDocName,
                              notes: notesController.text.trim(),
                              type: selectedType,
                              date: combinedDateTime,
                            );
                            setState(() {
                              _interactions.insert(0, localMock);
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Interaction logged locally (Backend Offline)'),
                                  backgroundColor: Color(0xFF2563EB),
                                ),
                              );
                            }
                          }
                          _loadData();
                        },
                        child: const Text(
                          'Save Discussion Log',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String role = SessionState.getRole(user?.userMetadata);
    final isRep = role == 'Medical Representative';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 960;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: isWide ? null : const Sidebar(),
      body: Row(
        children: [
          if (isWide)
            const Sidebar(isPermanent: true),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  _buildAppBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroCard(),
                          const SizedBox(height: 24),
                          
                          // Interactions Statistics Row
                          _buildInteractionsStatsRow(),
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Recent Communications Log',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              if (isRep)
                                ElevatedButton.icon(
                                  onPressed: _showAddInteractionDialog,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Log Interaction'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0D9488), // Teal theme
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _isLoading
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(32.0),
                                  child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                                ))
                              : _interactions.isEmpty
                                  ? _buildEmptyState()
                                  : _buildLogsListView(_interactions),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      color: AppTheme.surfaceColor,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width <= 960) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.textMutedColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
            const SizedBox(width: 12),
          ],
          const Text(
            'Doctor Interaction Registry',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textMainColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -30,
            child: Opacity(
              opacity: 0.1,
              child: const Icon(Icons.chat_bubble_rounded, size: 200, color: Colors.white),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Communication Loop Logs',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    const Text(
                      'Register face-to-face checkups, phone check-ins, and virtual diagnostics feedback.',
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Total Logs: ${_interactions.length}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ).animate().scale(delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.hairlineColor),
      ),
      child: const Center(
        child: Text(
          'No interactions registered in this loop yet.',
          style: TextStyle(color: AppTheme.textMutedColor),
        ),
      ),
    );
  }

  Widget _buildLogsListView(List<Interaction> logs) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final i = logs[index];
        final docName = i.doctorName.isNotEmpty ? i.doctorName : _getDoctorName(i.doctorId);
        final color = _getTypeColor(i.type);
        final icon = _getTypeIcon(i.type);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.hairlineColor),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.01),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color.withOpacity(0.08),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              docName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMainColor,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              i.type,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Text(
                      i.date != null ? i.date!.toLocal().toString().substring(0, 10) : 'Recent',
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Established Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  i.notes,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 400.ms, delay: (index * 40).ms).slideY(begin: 0.05);
      },
    );
  }

  TimeOfDay? _parseTimeString(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return null;
    try {
      final is12Hour = timeStr.contains('AM') || timeStr.contains('PM');
      if (is12Hour) {
        final isPM = timeStr.contains('PM');
        final cleanStr = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
        final parts = cleanStr.split(':');
        if (parts.length != 2) return null;
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        if (isPM) {
          if (hour < 12) hour += 12;
        } else {
          if (hour == 12) hour = 0;
        }
        return TimeOfDay(hour: hour, minute: minute);
      } else {
        final parts = timeStr.split(':');
        if (parts.length != 2) return null;
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {
      return null;
    }
  }

  bool _isTimeBetween(TimeOfDay selected, TimeOfDay start, TimeOfDay end) {
    final selMin = selected.hour * 60 + selected.minute;
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    if (startMin <= endMin) {
      return selMin >= startMin && selMin <= endMin;
    } else {
      return selMin >= startMin || selMin <= endMin;
    }
  }

  Widget _buildInteractionsStatsRow() {
    final totalCount = _interactions.length;
    final inPersonCount = _interactions.where((e) => e.type.toLowerCase().contains('person') || e.type.toLowerCase().contains('in-person')).length;
    final virtualCount = _interactions.where((e) => e.type.toLowerCase().contains('virtual')).length;

    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Total Syncs',
            value: '$totalCount',
            icon: Icons.chat_rounded,
            accentColor: const Color(0xFF0D9488),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'In-person Visits',
            value: '$inPersonCount',
            icon: Icons.people_rounded,
            accentColor: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Virtual / Remotes',
            value: '$virtualCount',
            icon: Icons.videocam_rounded,
            accentColor: const Color(0xFF7C3AED),
          ),
        ),
      ],
    );
  }
}
