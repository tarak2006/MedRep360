import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/sidebar.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../../theme_config.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Onboarded: ${newDoctor.name} ($status)'),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Onboarded (Demo Mode): ${mockDoc.name} ($status)'),
            backgroundColor: const Color(0xFF2563EB),
          ),
        );
      }
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

  Future<void> _scheduleCallDialog() async {
    if (!_formKey.currentState!.validate()) return;

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate == null) return;

    if (!mounted) return;
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 10, minute: 0),
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
                backgroundColor: const Color(0xFFEF4444),
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted doctor: ${doc.name}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
        _fetchDoctors();
      } else {
        setState(() {
          _doctors.removeWhere((d) => d.id == doc.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted doctor (Demo Mode): ${doc.name}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 960;

    final filteredDoctors = _doctors.where((doc) {
      final nameMatches = doc.name.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_statusFilter == "All") return nameMatches;
      return nameMatches && doc.status == _statusFilter;
    }).toList();

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
                          
                          if (isWide) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: _buildFormSection(isWide),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 5,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildListHeader(),
                                      const SizedBox(height: 16),
                                      _isLoadingDoctors
                                          ? const Center(child: Padding(
                                              padding: EdgeInsets.all(32.0),
                                              child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                                            ))
                                          : filteredDoctors.isEmpty
                                              ? _buildEmptyState()
                                              : _buildDoctorsListView(filteredDoctors),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            _buildFormSection(isWide),
                            const SizedBox(height: 32),
                            _buildListHeader(),
                            const SizedBox(height: 16),
                            _isLoadingDoctors
                                ? const Center(child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: CircularProgressIndicator(color: Color(0xFF1E3A8A)),
                                  ))
                                : filteredDoctors.isEmpty
                                    ? _buildEmptyState()
                                    : _buildDoctorsListView(filteredDoctors),
                          ],
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
            'Onboard & Portfolio Sync',
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
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor], // Sky blue to Cobalt
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
              child: const Icon(Icons.person_add_alt_1_rounded, size: 200, color: Colors.white),
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
                      'Account Onboarding Console',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    const Text(
                      'Register primary profiles, log clinic hours, and schedule initial sync targets.',
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
                    'Onboarded: ${_doctors.length}',
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

  Widget _buildFormSection(bool isWide) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.hairlineColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.01),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.assignment_ind_rounded, color: AppTheme.primaryColor, size: 22),
                SizedBox(width: 10),
                Text(
                  'Primary Account Profiler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMainColor),
                ),
              ],
            ),
            const Divider(color: Color(0xFFF1F5F9), height: 32),
            
            // Grid Form fields
            LayoutBuilder(
              builder: (context, constraints) {
                final useRow = constraints.maxWidth > 760;
                return Column(
                  children: [
                    if (useRow) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextFormField(_nameController, 'Doctor Full Name *', 'e.g. Dr. Arthur Pendelton', true)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextFormField(_mobileController, 'Mobile Phone *', 'e.g. +35389000000', true)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextFormField(_specialtyController, 'Clinical Specialty', 'e.g. Cardiology, GP', false)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextFormField(_emailController, 'Email ID', 'e.g. arthur@hospital.org', false)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildTextFormField(_locationController, 'Clinical Region / Location', 'e.g. Dublin South', false)),
                          const SizedBox(width: 20),
                          Expanded(child: _buildTextFormField(_addressController, 'Detailed Address', 'e.g. St. James Hospital Block B', false)),
                        ],
                      ),
                    ] else ...[
                      _buildTextFormField(_nameController, 'Doctor Full Name *', 'e.g. Dr. Arthur Pendelton', true),
                      const SizedBox(height: 16),
                      _buildTextFormField(_mobileController, 'Mobile Phone *', 'e.g. +35389000000', true),
                      const SizedBox(height: 16),
                      _buildTextFormField(_specialtyController, 'Clinical Specialty', 'e.g. Cardiology, GP', false),
                      const SizedBox(height: 16),
                      _buildTextFormField(_emailController, 'Email ID', 'e.g. arthur@hospital.org', false),
                      const SizedBox(height: 16),
                      _buildTextFormField(_locationController, 'Clinical Region / Location', 'e.g. Dublin South', false),
                      const SizedBox(height: 16),
                      _buildTextFormField(_addressController, 'Detailed Address', 'e.g. St. James Hospital Block B', false),
                    ]
                  ],
                );
              },
            ),
            
            const SizedBox(height: 24),
            
            // Available times row
            const Text(
              'On-call Availability Windows',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.hairlineColor),
                    ),
                    onPressed: () => _selectAvailabilityTime(true),
                    icon: const Icon(Icons.access_time_rounded, size: 16, color: AppTheme.textMutedColor),
                    label: Text(_availableFrom.isNotEmpty ? 'From: $_availableFrom' : 'Available From', style: const TextStyle(color: AppTheme.textMutedColor)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: AppTheme.hairlineColor),
                    ),
                    onPressed: () => _selectAvailabilityTime(false),
                    icon: const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF64748B)),
                    label: Text(_availableTo.isNotEmpty ? 'To: $_availableTo' : 'Available To'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Dynamic custom fields
            _buildCustomFieldsSection(),
            
            const SizedBox(height: 32),
            
            // Submit Button Actions
            if (_isSubmitting)
              const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final wideButtons = constraints.maxWidth > 600;
                  final buttonList = [
                    Expanded(
                      flex: wideButtons ? 1 : 0,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF64748B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _submitOnboarding("Saved"),
                          icon: const Icon(Icons.save_rounded, size: 16),
                          label: const Text('Save Local Profile', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    SizedBox(width: wideButtons ? 12 : 0, height: wideButtons ? 0 : 12),
                    Expanded(
                      flex: wideButtons ? 1 : 0,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: _scheduleCallDialog,
                          icon: const Icon(Icons.calendar_month_rounded, size: 16),
                          label: const Text('Schedule Initial Call', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    SizedBox(width: wideButtons ? 12 : 0, height: wideButtons ? 0 : 12),
                    Expanded(
                      flex: wideButtons ? 1 : 0,
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: AppTheme.backgroundColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _submitOnboarding("MedRep Launched"),
                          icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                          label: const Text('Launch MedRep', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ];
                  
                  return wideButtons
                      ? Row(children: buttonList)
                      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: buttonList);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextFormField(TextEditingController controller, String label, String hint, bool required) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          validator: required
              ? (val) => val == null || val.trim().isEmpty ? 'Required field' : null
              : null,
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
              'Custom Diagnostic Attributes',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
            ),
            TextButton.icon(
              onPressed: _addCustomField,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Attribute', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        if (_customFields.isNotEmpty) const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _customFields.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customFields[index].key,
                      decoration: InputDecoration(
                        hintText: 'Key (e.g. License ID)',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _customFields[index].value,
                      decoration: InputDecoration(
                        hintText: 'Value (e.g. LIC-2938)',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFEF4444)),
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

  Widget _buildListHeader() {
    return Row(
      children: [
        const Text(
          'Onboarded Directory',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMainColor),
        ),
        const Spacer(),
        // Status Filter dropdown
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.hairlineColor),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _statusFilter,
              items: ['All', 'Saved', 'Call Scheduled', 'MedRep Launched'].map((status) {
                return DropdownMenuItem<String>(value: status, child: Text(status, style: const TextStyle(fontSize: 12)));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _statusFilter = val);
              },
            ),
          ),
        ),
      ],
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
          'No clinic records fit your current filtering criteria.',
          style: TextStyle(color: AppTheme.textMutedColor),
        ),
      ),
    );
  }

  Widget _buildDoctorsListView(List<Doctor> filteredDoctors) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredDoctors.length,
      itemBuilder: (context, index) {
        final doc = filteredDoctors[index];
        
        Color badgeBg = const Color(0xFFF1F5F9);
        Color badgeText = const Color(0xFF475569);
        if (doc.status == 'MedRep Launched') {
          badgeBg = AppTheme.primaryColor.withOpacity(0.12);
          badgeText = AppTheme.primaryColor;
        } else if (doc.status == 'Call Scheduled') {
          badgeBg = const Color(0xFFFFFBEB);
          badgeText = const Color(0xFFD97706);
        } else if (doc.status == 'Saved') {
          badgeBg = const Color(0xFFECFDF5);
          badgeText = const Color(0xFF059669);
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.hairlineColor),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.01),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                child: Text(
                  doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(
                doc.name,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMainColor, fontSize: 15),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  '${doc.specialty} • ${doc.region} • ${doc.mobile}',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      doc.status,
                      style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                    onPressed: () => _deleteDoctorConfirm(doc),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
