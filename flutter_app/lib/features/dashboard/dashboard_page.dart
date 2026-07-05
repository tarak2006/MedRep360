import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/session_state.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/sidebar.dart';
import '../../services/api_service.dart';
import '../../models/lead.dart';
import '../../models/interaction.dart';
import '../../models/doctor.dart';
import '../doctors/doctors_page.dart';
import '../leads/leads_page.dart';
import '../../theme_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;

  List<Lead> _leads = [];
  List<Interaction> _interactions = [];
  List<Doctor> _doctors = [];
  
  // Selected doctor index in the split-view panel
  int _selectedDoctorIndex = 0;
  
  // Search text controller
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.fetchLeads(),
        _apiService.fetchInteractions(),
        _apiService.fetchDoctors(),
      ]);
      setState(() {
        _leads = futures[0] as List<Lead>;
        _interactions = futures[1] as List<Interaction>;
        _doctors = futures[2] as List<Doctor>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final String name = SessionState.getName(user?.userMetadata);
    final String role = SessionState.getRole(user?.userMetadata);

    final isRep = role == 'Medical Representative';
    final isManager = role == 'Operations Manager';
    final isTech = role == 'Technician';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 960;
    final isExtraWide = size.width > 1280;

    // Filter doctors based on search
    final filteredDoctors = _doctors.where((doc) {
      return doc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          doc.specialty.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: isWide ? null : const Sidebar(),
      body: Row(
        children: [
          // Sidebar Left Panel (Desktop only)
          if (isWide)
            const Sidebar(isPermanent: true),
            
          // Main Scrollable Area
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // Top Header Bar
                  _buildHeader(context, name, role),
                  
                  // Main Body Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Banner Row
                          _buildGreetingBanner(name, isRep, isManager, isTech),
                          const SizedBox(height: 24),
                          
                          // Quick Stats Widgets (Grid)
                          _buildQuickStats(isRep, isManager, isTech, isExtraWide),
                          const SizedBox(height: 24),

                          // Split panel: Left (Lists) vs Right (Calendar & reads)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left panel (Main console with patient lists & details)
                              Expanded(
                                flex: 3,
                                child: Column(
                                  children: [
                                    _buildWorkspaceSplitConsole(filteredDoctors, isRep, isManager, isTech, isWide),
                                  ],
                                ),
                              ),
                              
                              // Right panel (Calendar & Daily Read - desktop only)
                              if (isExtraWide) ...[
                                const SizedBox(width: 24),
                                SizedBox(
                                  width: 320,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildCalendarWidget(),
                                      const SizedBox(height: 24),
                                      _buildUpcomingEvents(),
                                      const SizedBox(height: 24),
                                      _buildDailyReadCard(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Display calendar widgets stacked on smaller screens
                          if (!isExtraWide) ...[
                            const SizedBox(height: 24),
                            _buildCalendarWidget(),
                            const SizedBox(height: 24),
                            _buildUpcomingEvents(),
                            const SizedBox(height: 24),
                            _buildDailyReadCard(),
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

  // Header Bar with search, notifications, profile
  Widget _buildHeader(BuildContext context, String name, String role) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        children: [
          // Mobile Menu Drawer Button
          if (MediaQuery.of(context).size.width <= 960) ...[
            IconButton(
              icon: const Icon(Icons.menu, color: Color(0xFF64748B)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
            const SizedBox(width: 12),
          ],
          
          // Search Input
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Search patient database, doctor specialty...',
                  hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Chat / messages
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF64748B), size: 22),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/interactions');
            },
          ),
          
          // Notifications
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF64748B), size: 24),
            onPressed: () {},
          ),
          
          const SizedBox(width: 12),
          
          // User Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF1E3A8A),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Greeting Banner
  Widget _buildGreetingBanner(String name, bool isRep, bool isManager, bool isTech) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Vibrant Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Graphic abstract design backdrops
          Positioned(
            right: -20,
            bottom: -30,
            child: Opacity(
              opacity: 0.15,
              child: const Icon(Icons.heart_broken_sharp, size: 260, color: Colors.white),
            ),
          ),
          
          // Illustration overlay
          Positioned(
            right: 40,
            bottom: 0,
            top: 10,
            child: Image.asset(
              'assets/images/doctor_avatar.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const SizedBox(),
            ).animate().fade(duration: 800.ms).slideY(begin: 0.2),
          ),
          
          // Banner text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $name!',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ).animate().fade().slideY(begin: 0.1),
                const SizedBox(height: 8),
                Text(
                  isRep
                      ? 'You have ${_doctors.length} onboarded clinics to coordinate today.'
                      : (isManager
                          ? 'Operational control: ${_leads.where((e) => e.status != 'Resolved').length} pending leads.'
                          : 'You are assigned ${_leads.where((e) => e.status == 'In Progress').length} resolution tasks.'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(bool isRep, bool isManager, bool isTech, bool isExtraWide) {
    final List<Widget> stats = [];

    if (isRep) {
      stats.add(
        DashboardCard(
          title: 'Doctors Onboarded',
          value: '${_doctors.length}',
          icon: Icons.people_rounded,
          accentColor: const Color(0xFF2563EB),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Interactions Logged',
          value: '${_interactions.length}',
          icon: Icons.chat_bubble_outline_rounded,
          accentColor: const Color(0xFF0D9488),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Scheduled Syncs',
          value: '${_doctors.where((d) => d.status == 'Call Scheduled').length}',
          icon: Icons.calendar_month_rounded,
          accentColor: const Color(0xFFD97706),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'MedRep Active',
          value: '${_doctors.where((d) => d.status == 'MedRep Launched').length}',
          icon: Icons.bolt_rounded,
          accentColor: AppTheme.primaryColor,
        ),
      );
    } else if (isTech) {
      final assignedLeads = _leads.where((e) => e.assignedTo != null && e.assignedTo!.isNotEmpty).toList();
      stats.add(
        DashboardCard(
          title: 'Assigned Issues',
          value: '${assignedLeads.where((e) => e.status != 'Resolved').length}',
          icon: Icons.assignment_late_rounded,
          accentColor: const Color(0xFFEA580C),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Issues Resolved',
          value: '${assignedLeads.where((e) => e.status == 'Resolved').length}',
          icon: Icons.task_alt_rounded,
          accentColor: const Color(0xFF16A34A),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Target Clinic Portfolio',
          value: '${_doctors.length}',
          icon: Icons.local_hospital_rounded,
          accentColor: const Color(0xFF2563EB),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Total Logs Recorded',
          value: '${_interactions.length}',
          icon: Icons.checklist_rtl_rounded,
          accentColor: const Color(0xFF0D9488),
        ),
      );
    } else {
      // Operations Manager
      stats.add(
        DashboardCard(
          title: 'Active Issues / Leads',
          value: '${_leads.where((e) => e.status != 'Resolved').length}',
          icon: Icons.warning_rounded,
          accentColor: const Color(0xFFEA580C),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Clinic Directory',
          value: '${_doctors.length}',
          icon: Icons.people_rounded,
          accentColor: const Color(0xFF2563EB),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Logs Submitted',
          value: '${_interactions.length}',
          icon: Icons.question_answer_rounded,
          accentColor: const Color(0xFF0D9488),
        ),
      );
      stats.add(
        DashboardCard(
          title: 'Unassigned Leads',
          value: '${_leads.where((e) => e.assignedTo == null || e.assignedTo!.isEmpty).length}',
          icon: Icons.person_add_disabled_rounded,
          accentColor: const Color(0xFFEF4444),
        ),
      );
    }

    return Row(
      children: stats.map((widget) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: widget,
          ),
        );
      }).toList(),
    );
  }

  // Interactive console combining patient list and details panel
  Widget _buildWorkspaceSplitConsole(List<Doctor> filteredDoctors, bool isRep, bool isManager, bool isTech, bool isWide) {
    if (filteredDoctors.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No patient/doctor records found matching query.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    // Guard selected index
    if (_selectedDoctorIndex >= filteredDoctors.length) {
      _selectedDoctorIndex = 0;
    }

    final selectedDoctor = filteredDoctors[_selectedDoctorIndex];

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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isPaneSplit = constraints.maxWidth > 700;
          
          Widget patientList() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 20.0, top: 20.0, bottom: 8.0),
                  child: Text(
                    'Patient List / Doctors',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMainColor),
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredDoctors.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.hairlineColor, height: 1),
                  itemBuilder: (context, index) {
                    final doc = filteredDoctors[index];
                    final isSelected = index == _selectedDoctorIndex;
                    
                    // Style attributes to match Stacy Mitchell profile mock
                    // Let's generate nice colorful avatar templates
                    Color avatarBg = const Color(0xFFFCE7F3);
                    Color avatarText = const Color(0xFFDB2777);
                    if (index % 3 == 1) {
                      avatarBg = const Color(0xFFE0F2FE);
                      avatarText = const Color(0xFF0284C7);
                    } else if (index % 3 == 2) {
                      avatarBg = const Color(0xFFECFDF5);
                      avatarText = const Color(0xFF059669);
                    }

                    // Visit types / status labels
                    String visitType = 'Routine Checkup';
                    Color visitTagColor = const Color(0xFF3B82F6);
                    if (doc.status == 'MedRep Launched') {
                      visitType = 'MedRep Active';
                      visitTagColor = AppTheme.primaryColor;
                    } else if (doc.status == 'Call Scheduled') {
                      visitType = 'Scheduled Call';
                      visitTagColor = const Color(0xFFF59E0B);
                    } else if (doc.status == 'Saved') {
                      visitType = 'Onboarded';
                      visitTagColor = const Color(0xFF10B981);
                    }

                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
                        tileColor: isSelected ? const Color(0xFFF1F5F9).withOpacity(0.5) : Colors.transparent,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: avatarBg,
                          child: Text(
                            doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                            style: TextStyle(color: avatarText, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        title: Text(
                          doc.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              visitType,
                              style: TextStyle(color: visitTagColor, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              doc.region,
                              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            ),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCE7F3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            doc.availableFrom.isNotEmpty ? doc.availableFrom : '10:00 AM',
                            style: const TextStyle(color: Color(0xFFDB2777), fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            _selectedDoctorIndex = index;
                          });
                        },
                      ),
                    );
                  },
                ),
              ],
            );
          }

          Widget detailsPane() {
            // Colors matching Stacy/Denzel design details
            return Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: isPaneSplit
                    ? const BorderRadius.only(topRight: Radius.circular(24), bottomRight: Radius.circular(24))
                    : BorderRadius.circular(24),
                border: isPaneSplit
                    ? const Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Consultation Details',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 20),
                  
                  // Doctor Info row
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: const Color(0xFFE0F2FE),
                        child: Text(
                          selectedDoctor.name.isNotEmpty ? selectedDoctor.name[0].toUpperCase() : 'D',
                          style: const TextStyle(color: Color(0xFF0369A1), fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedDoctor.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Specialty: ${selectedDoctor.specialty} • ${selectedDoctor.mobile}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  const SizedBox(height: 20),
                                   // Clinic Focus / Custom Attributes Row
                  Text(
                    selectedDoctor.customFields.isNotEmpty ? 'Custom Attributes & Focus' : 'Clinic Focus Areas',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (selectedDoctor.customFields.isNotEmpty)
                        ...selectedDoctor.customFields.entries.map((entry) {
                          return _buildIndicatorChip(Icons.label_outline_rounded, '${entry.key}: ${entry.value}', const Color(0xFF0D9488));
                        })
                      else ...[
                        if (selectedDoctor.specialty.toLowerCase().contains('physician') || selectedDoctor.specialty.toLowerCase().contains('general')) ...[
                          _buildIndicatorChip(Icons.thermostat_outlined, 'General Medicine', const Color(0xFFDB2777)),
                          _buildIndicatorChip(Icons.healing_rounded, 'Preventive Health', const Color(0xFF2563EB)),
                          _buildIndicatorChip(Icons.favorite_outline_rounded, 'Chronic Care', const Color(0xFF0D9488)),
                        ] else if (selectedDoctor.specialty.toLowerCase().contains('cardio')) ...[
                          _buildIndicatorChip(Icons.favorite_rounded, 'Cardiovascular Health', const Color(0xFFE11D48)),
                          _buildIndicatorChip(Icons.monitor_heart_rounded, 'Hypertension', const Color(0xFF2563EB)),
                          _buildIndicatorChip(Icons.speed_rounded, 'Lipid Sync', const Color(0xFF0D9488)),
                        ] else if (selectedDoctor.specialty.toLowerCase().contains('pediatr')) ...[
                          _buildIndicatorChip(Icons.child_care_rounded, 'Pediatric Care', const Color(0xFFDB2777)),
                          _buildIndicatorChip(Icons.healing_rounded, 'Immunization Focus', const Color(0xFF2563EB)),
                          _buildIndicatorChip(Icons.restaurant_rounded, 'Child Nutrition', const Color(0xFF0D9488)),
                        ] else if (selectedDoctor.specialty.toLowerCase().contains('dermat')) ...[
                          _buildIndicatorChip(Icons.face_retouching_natural_rounded, 'Dermatology Care', const Color(0xFFDB2777)),
                          _buildIndicatorChip(Icons.clean_hands_rounded, 'Eczema Treatment', const Color(0xFF2563EB)),
                          _buildIndicatorChip(Icons.health_and_safety_rounded, 'Skin Screening', const Color(0xFF0D9488)),
                        ] else ...[
                          _buildIndicatorChip(Icons.medical_services_outlined, selectedDoctor.specialty.isNotEmpty ? selectedDoctor.specialty : 'General Practice', const Color(0xFF7C3AED)),
                          _buildIndicatorChip(Icons.location_on_outlined, selectedDoctor.region, const Color(0xFF2563EB)),
                          _buildIndicatorChip(Icons.info_outline_rounded, selectedDoctor.status, const Color(0xFF0D9488)),
                        ]
                      ]
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Builder(
                    builder: (context) {
                      final docInteractions = _interactions.where((i) => i.doctorId == selectedDoctor.id).toList();
                      docInteractions.sort((a, b) => (b.date ?? DateTime.now()).compareTo(a.date ?? DateTime.now()));
                      
                      String lastCheckedValue = 'No prior interactions logged yet.';
                      String observationValue = 'No prior observation notes found. Ready to coordinate first visit.';
                      
                      if (docInteractions.isNotEmpty) {
                        final last = docInteractions.first;
                        final dateStr = last.date != null 
                            ? "${last.date!.day} ${_getMonthName(last.date!.month)} ${last.date!.year}" 
                            : "Recently";
                        lastCheckedValue = 'Logged ${last.type} Visit on $dateStr';
                        observationValue = last.notes.trim().isNotEmpty ? last.notes : 'Discussion completed successfully. No details recorded.';
                      } else if (selectedDoctor.scheduledTime != null) {
                        final sched = selectedDoctor.scheduledTime!;
                        lastCheckedValue = 'Initial meeting scheduled for ${sched.day} ${_getMonthName(sched.month)} ${sched.year} at ${sched.hour}:${sched.minute.toString().padLeft(2, '0')}';
                        observationValue = 'Awaiting initial representative call. Portfolio sync is pending doctor availability.';
                      } else if (selectedDoctor.address.isNotEmpty) {
                        observationValue = 'Clinic location registered at: ${selectedDoctor.address}. On-call hours: ${selectedDoctor.availableFrom} - ${selectedDoctor.availableTo}.';
                      }
                      
                      List<String> discussionPoints = [];
                      if (selectedDoctor.specialty.toLowerCase().contains('physician') || selectedDoctor.specialty.toLowerCase().contains('general')) {
                        discussionPoints = [
                          '• Detail Multi-Vit Clinica & pediatric formulations.',
                          '• Introduce Thermo-Fever Oral Solution parameters.',
                          '• Leave brochures & starter kits for cold management.'
                        ];
                      } else if (selectedDoctor.specialty.toLowerCase().contains('cardio')) {
                        discussionPoints = [
                          '• Detail Cardio-Core XR efficacy & safety data.',
                          '• Deliver starter kits of LipidSync 10mg.',
                          '• Share clinical trials on arterial stiffness.'
                        ];
                      } else if (selectedDoctor.specialty.toLowerCase().contains('pediatr')) {
                        discussionPoints = [
                          '• Highlight ToddlerNutri developmental supplements.',
                          '• Discuss Immunization tracker tool integration.',
                          '• Leave educational poster charts for waiting area.'
                        ];
                      } else if (selectedDoctor.specialty.toLowerCase().contains('dermat')) {
                        discussionPoints = [
                          '• Present SkinCare-Derm lotion clinical data.',
                          '• Discuss patient feedback statistics for Eczema Relief.',
                          '• Leave tester kits of ClearComplex skin gels.'
                        ];
                      } else {
                        discussionPoints = [
                          '• Establish clinic product requirements for primary care.',
                          '• Deliver baseline samples of analgesic & cold remedies.',
                          '• Highlight local pharmacy distribution channels.'
                        ];
                      }
                      final prescriptionValue = discussionPoints.join('\n');
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Last Visit', lastCheckedValue),
                          const SizedBox(height: 14),
                          _buildDetailRow('Latest Notes / Observation', observationValue),
                          const SizedBox(height: 14),
                          _buildDetailRow('Target Products / Detailing Plan', prescriptionValue),
                        ],
                      );
                    }
                  ),
                  
                  const SizedBox(height: 28),
                  
                  // Direct Action button inside the console
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E3A8A),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // Dynamically link to action page based on role
                        if (isRep) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const DoctorsPage()),
                          );
                        } else if (isManager || isTech) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LeadsPage()),
                          );
                        }
                      },
                      icon: const Icon(Icons.rocket_launch_rounded, size: 18),
                      label: Text(
                        isRep
                            ? 'Manage Doctor Portfolio'
                            : (isManager ? 'Manage Escalation Leads' : 'View Actionable Tasks'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (isPaneSplit) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: patientList()),
                Expanded(flex: 5, child: detailsPane()),
              ],
            );
          } else {
            return Column(
              children: [
                patientList(),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                detailsPane(),
              ],
            );
          }
        },
      ),
    );
  }

  // Symptom pills
  Widget _buildIndicatorChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.4),
        ),
      ],
    );
  }

  String _getMonthFullName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  // Smart minimalist Calendar widget
  Widget _buildCalendarWidget() {
    final now = DateTime.now();
    final monthStr = "${_getMonthFullName(now.month)} ${now.year}";

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calendar',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: monthStr,
                  items: [monthStr].map((m) {
                    return DropdownMenuItem<String>(
                      value: m,
                      child: Text(m, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Day Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((day) {
              return SizedBox(
                width: 32,
                child: Text(
                  day,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          
          // Render days dynamically
          _buildCalendarDaysGrid(),
        ],
      ),
    );
  }

  Widget _buildCalendarDaysGrid() {
    final List<Widget> dayWidgets = [];
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final today = now.day;

    // Days in current month
    final totalDays = DateTime(currentYear, currentMonth + 1, 0).day;
    // Weekday of the 1st day of month (1 for Mon, 7 for Sun)
    final firstWeekday = DateTime(currentYear, currentMonth, 1).weekday;
    
    // In our SUN to SAT layout, Sunday should be index 0, Monday index 1, ..., Saturday index 6.
    final blankSpaces = firstWeekday == 7 ? 0 : firstWeekday;

    // Add empty space before the 1st day
    for (int i = 0; i < blankSpaces; i++) {
      dayWidgets.add(const SizedBox(width: 32, height: 32));
    }

    // Highlight some days around today
    final highlightDaysWithDots = <int>{};
    for (final offset in [-15, -9, -2, 1, 5]) {
      final targetDay = today + offset;
      if (targetDay > 0 && targetDay <= totalDays) {
        highlightDaysWithDots.add(targetDay);
      }
    }

    for (int day = 1; day <= totalDays; day++) {
      final isToday = day == today;
      final hasDot = highlightDaysWithDots.contains(day);

      dayWidgets.add(
        SizedBox(
          width: 32,
          height: 32,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF1E3A8A) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isToday
                        ? Colors.white
                        : (day % 7 == 0 || (day + 1) % 7 == 0 ? const Color(0xFF94A3B8) : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              if (hasDot && !isToday)
                Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444), // Red highlight dot
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    // Grid build
    final List<Widget> rows = [];
    for (int i = 0; i < dayWidgets.length; i += 7) {
      final end = (i + 7 < dayWidgets.length) ? i + 7 : dayWidgets.length;
      final rowItems = dayWidgets.sublist(i, end);
      
      // Pad end if row is shorter than 7
      while (rowItems.length < 7) {
        rowItems.add(const SizedBox(width: 32, height: 32));
      }
      
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: rowItems,
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  // Upcoming meetings list
  Widget _buildUpcomingEvents() {
    final now = DateTime.now();
    final event1Date = "${now.day} ${_getMonthName(now.month)}, ${now.year} | 04:00 PM";
    final threeDaysLater = now.add(const Duration(days: 3));
    final event2Date = "${threeDaysLater.day} ${_getMonthName(threeDaysLater.month)}, ${threeDaysLater.year} | 11:30 AM";

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Upcoming Meetings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacementNamed(context, '/interactions');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUpcomingEventItem('Monthly doctor\'s meet', event1Date, const Color(0xFFE0F2FE), const Color(0xFF0284C7)),
          const SizedBox(height: 10),
          _buildUpcomingEventItem('Clinical strategy sync', event2Date, const Color(0xFFFCE7F3), const Color(0xFFDB2777)),
        ],
      ),
    );
  }

  Widget _buildUpcomingEventItem(String title, String time, Color bg, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: bg,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calendar_today_rounded, size: 16, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Daily Read article card
  Widget _buildDailyReadCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?q=80&w=600&auto=format&fit=crop',
            height: 140,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(height: 140, color: const Color(0xFF3B82F6)),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'DAILY READ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.8),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Equitable medical education with efforts toward real change',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }
}