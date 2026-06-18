import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sidebar.dart';
import '../../models/interaction.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../../services/session_state.dart';

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
        return Colors.teal;
      case 'virtual':
        return Colors.blue;
      case 'phone':
        return Colors.orange;
      case 'email':
        return Colors.indigo;
      default:
        return Colors.grey;
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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    // Doctor selection
                    const Text(
                      'Select Doctor',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 8),
                    Builder(
                      builder: (context) {
                        final selectedDoc = _doctors.firstWhere((d) => d.id == selectedDoctorId, orElse: () => _doctors.first);
                        final String availabilityText = (selectedDoc.availableFrom.isNotEmpty && selectedDoc.availableTo.isNotEmpty)
                            ? 'Available: ${selectedDoc.availableFrom} to ${selectedDoc.availableTo}'
                            : 'Available: Not specified (All day)';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_filled_rounded, size: 16, color: Colors.blueAccent),
                              const SizedBox(width: 8),
                              Text(
                                availabilityText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Type selection
                    const Text(
                      'Interaction Type',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
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
                    const SizedBox(height: 16),

                    // Date & Time Picker Row
                    const Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Interaction Date',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Interaction Time',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}'),
                                  const Icon(Icons.calendar_today_rounded, color: Colors.blueAccent, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(selectedTime.format(context)),
                                  const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Notes input
                    const Text(
                      'Discussion Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'What did you discuss with the doctor?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                                        SizedBox(width: 8),
                                        Text('Doctor Unavailable'),
                                      ],
                                    ),
                                    content: Text('${selectedDoc.name} is only available from ${selectedDoc.availableFrom} until ${selectedDoc.availableTo}.\n\nSelected time: ${selectedTime.format(context)} is outside of their working hours. Please change the time.'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Interaction logged successfully!')),
                            );
                          } else {
                            // If backend failed/offline, save to local state for UX demonstration
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Interaction logged locally (Backend Offline)')),
                            );
                          }
                          _loadData();
                        },
                        child: const Text(
                          'Save Log',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Interaction Logs',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header Card
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00796B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.teal.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.teal.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Doctor Interactions',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Track visits, discussions, and relationships.',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ).animate().fade(delay: 200.ms).slideY(begin: 0.3),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Total Logs: ${_interactions.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ).animate().fade(delay: 400.ms).scale(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Logs Header with FAB Action
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Discussions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (isRep)
                  ElevatedButton.icon(
                    onPressed: _showAddInteractionDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Log Interaction'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Interactions List View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _interactions.isEmpty
                      ? const Center(child: Text('No interactions logged.'))
                      : ListView.builder(
                          itemCount: _interactions.length,
                          itemBuilder: (context, index) {
                            final i = _interactions[index];
                            final doctorName = i.doctorName.isNotEmpty
                                ? i.doctorName
                                : _getDoctorName(i.doctorId);
                            final color = _getTypeColor(i.type);
                            final icon = _getTypeIcon(i.type);

                            return Card(
                              elevation: 4,
                              shadowColor: Colors.blueAccent.withOpacity(0.1),
                              margin: const EdgeInsets.only(bottom: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: Colors.blueAccent.withOpacity(0.05),
                                ),
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
                                              backgroundColor: color.withOpacity(0.1),
                                              child: Icon(icon, color: color),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  doctorName,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  i.type,
                                                  style: TextStyle(
                                                    color: color,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Text(
                                          i.date != null ? i.date!.toLocal().toString().substring(0, 10) : 'Recent',
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Discussion Notes:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      i.notes,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ).animate()
                             .fade(duration: 400.ms, delay: (50 * index).ms)
                             .slideY(begin: 0.1);
                          },
                        ),
            ),
          ].animate(interval: 50.ms).fade(duration: 400.ms),
        ),
      ),
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
}
