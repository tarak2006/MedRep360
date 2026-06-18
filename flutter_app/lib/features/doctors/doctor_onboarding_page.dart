import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/sidebar.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';

class DoctorOnboardingPage extends StatefulWidget {
  const DoctorOnboardingPage({super.key});

  @override
  State<DoctorOnboardingPage> createState() => _DoctorOnboardingPageState();
}

class _DoctorOnboardingPageState extends State<DoctorOnboardingPage> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // Text Controllers
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();

  String _availableFrom = "";
  String _availableTo = "";
  final List<MapEntry<TextEditingController, TextEditingController>> _customFields = [];

  bool _isSubmitting = false;
  bool _isLoadingDoctors = true;
  List<Doctor> _doctors = [];
  String _searchQuery = "";
  String _statusFilter = "All";

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _specialtyController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    for (var entry in _customFields) {
      entry.key.dispose();
      entry.value.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoadingDoctors = true);
    try {
      final doctorsList = await _apiService.fetchDoctors();
      setState(() {
        _doctors = doctorsList;
        _isLoadingDoctors = false;
      });
    } catch (e) {
      setState(() => _isLoadingDoctors = false);
    }
  }

  // Common submit function
  Future<void> _submitOnboarding(String status, {DateTime? scheduledTime}) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final Map<String, String> customs = {};
    for (var entry in _customFields) {
      final k = entry.key.text.trim();
      final v = entry.value.text.trim();
      if (k.isNotEmpty && v.isNotEmpty) {
        customs[k] = v;
      }
    }

    final payload = {
      "name": _nameController.text.trim(),
      "mobile": _mobileController.text.trim(),
      "specialty": _specialtyController.text.trim().isNotEmpty 
          ? _specialtyController.text.trim() 
          : "General Practice",
      "email": _emailController.text.trim(),
      "region": _locationController.text.trim().isNotEmpty 
          ? _locationController.text.trim() 
          : "Not Specified",
      "address": _addressController.text.trim(),
      "status": status,
      if (scheduledTime != null) "scheduledTime": scheduledTime.toIso8601String(),
      "availableFrom": _availableFrom,
      "availableTo": _availableTo,
      "customFields": customs,
    };

    final newDoctor = await _apiService.createDoctor(payload);

    setState(() => _isSubmitting = false);

    if (newDoctor != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Onboarded: ${newDoctor.name} ($status)'),
          backgroundColor: Colors.green.shade700,
        ),
      );
      _clearForm();
      _fetchDoctors();
    } else {
      // Offline fallback
      final mockDoc = Doctor(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        name: payload['name'] as String,
        mobile: payload['mobile'] as String,
        specialty: payload['specialty'] as String,
        email: payload['email'] as String,
        region: payload['region'] as String,
        address: payload['address'] as String,
        status: status,
        scheduledTime: scheduledTime,
        availableFrom: _availableFrom,
        availableTo: _availableTo,
        customFields: customs,
      );
      setState(() {
        _doctors.insert(0, mockDoc);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Onboarded (Demo Mode): ${mockDoc.name} ($status)'),
          backgroundColor: Colors.blue.shade700,
        ),
      );
      _clearForm();
    }
  }

  void _clearForm() {
    _nameController.clear();
    _mobileController.clear();
    _specialtyController.clear();
    _emailController.clear();
    _locationController.clear();
    _addressController.clear();
    setState(() {
      _availableFrom = "";
      _availableTo = "";
      for (var entry in _customFields) {
        entry.key.dispose();
        entry.value.dispose();
      }
      _customFields.clear();
    });
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(MapEntry(TextEditingController(), TextEditingController()));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields[index].key.dispose();
      _customFields[index].value.dispose();
      _customFields.removeAt(index);
    });
  }

  Future<void> _selectAvailabilityTime(bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        final formattedTime = picked.format(context);
        if (isFrom) {
          _availableFrom = formattedTime;
        } else {
          _availableTo = formattedTime;
        }
      });
    }
  }

  // Launches dialog for scheduling date and time
  Future<void> _scheduleCallDialog() async {
    if (!_formKey.currentState!.validate()) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    final scheduledDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await _submitOnboarding("Call Scheduled", scheduledTime: scheduledDateTime);
  }

  Future<void> _deleteDoctorConfirm(Doctor doc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Doctor'),
          content: Text('Are you sure you want to delete ${doc.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      setState(() => _isSubmitting = true);
      final success = await _apiService.deleteDoctor(doc.id);
      setState(() => _isSubmitting = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted doctor: ${doc.name}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        _fetchDoctors();
      } else {
        // Offline fallback deletion
        setState(() {
          _doctors.removeWhere((d) => d.id == doc.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Deleted doctor (Demo Mode): ${doc.name}'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  Future<void> _editDoctorDialog(Doctor doc) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: doc.name);
    final mobileCtrl = TextEditingController(text: doc.mobile);
    final specialtyCtrl = TextEditingController(text: doc.specialty);
    final emailCtrl = TextEditingController(text: doc.email);
    final locationCtrl = TextEditingController(text: doc.region);
    final addressCtrl = TextEditingController(text: doc.address);
    String availableFrom = doc.availableFrom;
    String availableTo = doc.availableTo;
    String currentStatus = doc.status;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Doctor Details'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Name *'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: mobileCtrl,
                          decoration: const InputDecoration(labelText: 'Mobile *'),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter mobile' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: specialtyCtrl,
                          decoration: const InputDecoration(labelText: 'Specialty'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailCtrl,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationCtrl,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(labelText: 'Address'),
                        ),
                        const SizedBox(height: 12),
                        // Dropdown for Status
                        DropdownButtonFormField<String>(
                          value: currentStatus,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: () {
                            final list = ["Saved", "Call Scheduled", "AI Agent Launched", "Contact Now", "Already Contacted"];
                            if (!list.contains(currentStatus)) {
                              list.add(currentStatus);
                            }
                            return list.map((status) {
                              return DropdownMenuItem<String>(
                                value: status,
                                child: Text(status),
                              );
                            }).toList();
                          }(),
                          onChanged: (val) {
                            if (val != null) {
                              setDialogState(() => currentStatus = val);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      availableFrom = picked.format(context);
                                    });
                                  }
                                },
                                child: Text(availableFrom.isNotEmpty ? 'From: $availableFrom' : 'Available From'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final TimeOfDay? picked = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.now(),
                                  );
                                  if (picked != null) {
                                    setDialogState(() {
                                      availableTo = picked.format(context);
                                    });
                                  }
                                },
                                child: Text(availableTo.isNotEmpty ? 'To: $availableTo' : 'Available To'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    
                    final updatedPayload = {
                      "name": nameCtrl.text.trim(),
                      "mobile": mobileCtrl.text.trim(),
                      "specialty": specialtyCtrl.text.trim(),
                      "email": emailCtrl.text.trim(),
                      "region": locationCtrl.text.trim(),
                      "address": addressCtrl.text.trim(),
                      "status": currentStatus,
                      "availableFrom": availableFrom,
                      "availableTo": availableTo,
                    };

                    Navigator.pop(context);
                    setState(() => _isSubmitting = true);
                    final updatedDoc = await _apiService.updateDoctor(doc.id, updatedPayload);
                    setState(() => _isSubmitting = false);

                    if (updatedDoc != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated details for: ${updatedDoc.name}'),
                          backgroundColor: Colors.green.shade700,
                        ),
                      );
                      _fetchDoctors();
                    } else {
                      // Offline/Demo fallback update
                      final index = _doctors.indexWhere((d) => d.id == doc.id);
                      if (index != -1) {
                        setState(() {
                          _doctors[index] = Doctor(
                            id: doc.id,
                            name: updatedPayload['name'] as String,
                            mobile: updatedPayload['mobile'] as String,
                            specialty: updatedPayload['specialty'] as String,
                            email: updatedPayload['email'] as String,
                            region: updatedPayload['region'] as String,
                            address: updatedPayload['address'] as String,
                            status: currentStatus,
                            availableFrom: availableFrom,
                            availableTo: availableTo,
                            scheduledTime: doc.scheduledTime,
                            customFields: doc.customFields,
                          );
                        });
                      }
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Updated (Demo Mode): ${nameCtrl.text.trim()}'),
                          backgroundColor: Colors.blue.shade700,
                        ),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatusBadge(String status, DateTime? scheduledTime) {
    Color bg;
    Color text;
    IconData icon;

    switch (status) {
      case 'AI Agent Launched':
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        icon = Icons.rocket_launch_rounded;
        break;
      case 'Contact Now':
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        icon = Icons.phone_android_rounded;
        break;
      case 'Contacted Now':
      case 'Already Contacted':
        bg = Colors.teal.shade50;
        text = Colors.teal.shade800;
        icon = Icons.check_circle_rounded;
        break;
      case 'Call Scheduled':
        bg = Colors.amber.shade50;
        text = Colors.orange.shade800;
        icon = Icons.calendar_month_rounded;
        break;
      case 'Saved':
      case 'Created':
      default:
        bg = Colors.grey.shade100;
        text = Colors.grey.shade800;
        icon = Icons.save_rounded;
    }

    String label = status;
    if (status == 'Call Scheduled' && scheduledTime != null) {
      label = 'Scheduled: ${_formatDateTime(scheduledTime)}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: text.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: text,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final day = dt.day.toString().padLeft(2, '0');
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[dt.month - 1];
    final hour12 = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month, $hour12:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _doctors.where((doc) {
      final nameMatches = doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_statusFilter == "All") return nameMatches;
      return nameMatches && doc.status == _statusFilter;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Onboarding',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 2,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
      ),
      drawer: const Sidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Title Card
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF00ACC1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
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
                      Colors.blueAccent.withOpacity(0.4),
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
                          'Doctor Onboarding',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Register new doctors and configure AI Agent interactions.',
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
                        'Total Onboarded: ${_doctors.length}',
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

            // Form Layout Card
            Card(
              elevation: 4,
              shadowColor: Colors.blueAccent.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blueAccent.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.person_add_alt_1_rounded, color: Colors.blueAccent),
                          SizedBox(width: 10),
                          Text(
                            'Add New Doctor',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      
                      // Two column form layout (Responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          bool isWide = constraints.maxWidth > 800;
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: _buildLeftFields()),
                                    const SizedBox(width: 32),
                                    Expanded(child: _buildRightFields()),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildLeftFields(),
                                    const SizedBox(height: 16),
                                    _buildRightFields(),
                                  ],
                                );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Custom Field section
                      _buildCustomFieldsSection(),
                      
                      const SizedBox(height: 32),
                      
                      // Button Actions Row
                      if (_isSubmitting)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            bool isWide = constraints.maxWidth > 800;
                            final buttonList = [
                              // Button 1: Saved
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blueGrey.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _submitOnboarding("Saved"),
                                    icon: const Icon(Icons.save_rounded),
                                    label: const Text(
                                      'Saved',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12, height: 12),
                              // Button 2: Schedule Now
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange.shade800,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: _scheduleCallDialog,
                                    icon: const Icon(Icons.calendar_month_rounded),
                                    label: const Text(
                                      'Schedule Now',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12, height: 12),
                              // Button 3: Contact Now
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _submitOnboarding("Contact Now"),
                                    icon: const Icon(Icons.phone_android_rounded),
                                    label: const Text(
                                      'Contact Now',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12, height: 12),
                              // Button 4: Already Contacted
                              Expanded(
                                flex: isWide ? 1 : 0,
                                child: SizedBox(
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade700,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    onPressed: () => _submitOnboarding("Already Contacted"),
                                    icon: const Icon(Icons.check_circle_rounded),
                                    label: const Text(
                                      'Already Contacted',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ),
                            ];

                            return isWide
                                ? Row(children: buttonList)
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: buttonList,
                                  );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ).animate().fade(duration: 500.ms).slideY(begin: 0.05),
            
            const SizedBox(height: 36),

            // Onboarded Doctors Title & Filters
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Onboarded Doctors Log',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                // Filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _statusFilter,
                      items: ["All", "Saved", "Call Scheduled", "AI Agent Launched", "Contact Now", "Already Contacted"].map((String status) {
                        return DropdownMenuItem<String>(
                          value: status,
                          child: Text(status),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _statusFilter = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search by doctor name...',
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
            const SizedBox(height: 16),

            // Onboarded List View
            _isLoadingDoctors
                ? const Center(child: CircularProgressIndicator())
                : filteredDoctors.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Text(
                            'No onboarded doctors found.',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    : Card(
                        elevation: 4,
                        shadowColor: Colors.blueAccent.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.blueAccent.withOpacity(0.05)),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredDoctors.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, index) {
                              final doc = filteredDoctors[index];
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                  child: const Icon(Icons.person, color: Colors.blueAccent),
                                ),
                                title: Text(
                                  doc.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text('Mobile: ${doc.mobile.isNotEmpty ? doc.mobile : 'N/A'} • Specialty: ${doc.specialty}'),
                                    const SizedBox(height: 2),
                                    Text('Location: ${doc.region} • Email: ${doc.email.isNotEmpty ? doc.email : 'N/A'}'),
                                    if (doc.availableFrom.isNotEmpty && doc.availableTo.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Available: ${doc.availableFrom} to ${doc.availableTo}'),
                                    ],
                                    if (doc.customFields.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: doc.customFields.entries.map((entry) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blueAccent.withOpacity(0.05),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.blueAccent.withOpacity(0.1)),
                                            ),
                                            child: Text(
                                              '${entry.key}: ${entry.value}',
                                              style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildStatusBadge(doc.status, doc.scheduledTime),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                                      onPressed: () => _editDoctorDialog(doc),
                                      tooltip: 'Edit Doctor',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                      onPressed: () => _deleteDoctorConfirm(doc),
                                      tooltip: 'Delete Doctor',
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ).animate().fade(duration: 500.ms, delay: 200.ms),
          ],
        ),
      ),
    );
  }

  // Left Column Fields (Mandatory)
  Widget _buildLeftFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MANDATORY DETAILS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Doctor Name *',
            prefixIcon: const Icon(Icons.person_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter the doctor\'s name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _mobileController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Mobile Number *',
            prefixIcon: const Icon(Icons.phone_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (val) {
            if (val == null || val.trim().isEmpty) {
              return 'Please enter the mobile number';
            }
            // Basic numeric/length validation
            final reg = RegExp(r'^\+?[0-9]{10,13}$');
            if (!reg.hasMatch(val.trim())) {
              return 'Please enter a valid mobile number';
            }
            return null;
          },
        ),
      ],
    );
  }

  // Right Column Fields (Optional)
  Widget _buildRightFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OPTIONAL DETAILS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _specialtyController,
          decoration: InputDecoration(
            labelText: 'Specialty',
            prefixIcon: const Icon(Icons.medical_services_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'Email ID',
            prefixIcon: const Icon(Icons.email_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          validator: (val) {
            if (val != null && val.trim().isNotEmpty) {
              final reg = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!reg.hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _locationController,
          decoration: InputDecoration(
            labelText: 'Location',
            prefixIcon: const Icon(Icons.location_on_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),
        
        TextFormField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Address',
            prefixIcon: const Icon(Icons.home_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 16),

        // Doctor Availability Times
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectAvailabilityTime(true),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Available From',
                    prefixIcon: const Icon(Icons.access_time_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_availableFrom.isNotEmpty ? _availableFrom : 'Select Time'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => _selectAvailabilityTime(false),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Available To',
                    prefixIcon: const Icon(Icons.access_time_filled_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_availableTo.isNotEmpty ? _availableTo : 'Select Time'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomFieldsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'CUSTOM DETAILS (DYNAMIC)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0),
            ),
            TextButton.icon(
              onPressed: _addCustomField,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add Detail Row'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        if (_customFields.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 16.0),
            child: Text(
              'No custom fields added yet. Press the button to add headings and details (e.g. Hospital, Consultation Fee).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _customFields.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _customFields[index].key,
                        decoration: InputDecoration(
                          labelText: 'Side Heading (e.g. Hospital)',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _customFields[index].value,
                        decoration: InputDecoration(
                          labelText: 'Details / Values',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.redAccent),
                      onPressed: () => _removeCustomField(index),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
