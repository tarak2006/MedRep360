import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/dashboard_card.dart';
import '../../models/lead.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../../services/session_state.dart';
import '../../theme_config.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({super.key});

  @override
  State<LeadsPage> createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  bool _isLoading = true;
  List<Lead> leads = [];
  List<Doctor> doctors = [];
  final ApiService _apiService = ApiService();
  List<String> availableTechnicians = [
    'Tech Alex',
    'Tech Sarah',
    'Tech Rahul',
    'Tech Mike',
  ];

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.fetchLeads(),
        _apiService.fetchDoctors(),
        _apiService.fetchTechnicians(),
      ]);
      setState(() {
        leads = futures[0] as List<Lead>;
        doctors = futures[1] as List<Doctor>;
        availableTechnicians = futures[2] as List<String>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching data: $e')),
        );
      }
    }
  }

  void _showAddLeadDialog() {
    if (doctors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No doctors available. Add a doctor first!')),
      );
      return;
    }

    String? selectedDoctorName = doctors.first.name;
    final queryController = TextEditingController();

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
                          'Register New Lead',
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
                    
                    const Text(
                      'Select Doctor *',
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
                          value: selectedDoctorName,
                          isExpanded: true,
                          items: doctors.map((doc) {
                            return DropdownMenuItem<String>(
                              value: doc.name,
                              child: Text(doc.name),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedDoctorName = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Interest Details / Query Description *',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: queryController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe the doctor\'s query or interest raised...',
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

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA580C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () async {
                          if (queryController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please describe the query/interest details.')),
                            );
                            return;
                          }
                          Navigator.pop(context);
                          setState(() => _isLoading = true);

                          final payload = {
                            'doctor_name': selectedDoctorName,
                            'query': queryController.text.trim(),
                            'status': 'Pending',
                          };

                          final result = await _apiService.createLead(payload);
                          if (result != null) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lead registered successfully!'),
                                  backgroundColor: Color(0xFF16A34A),
                                ),
                              );
                            }
                          } else {
                            // Fallback mock insert
                            final localMock = Lead(
                              id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
                              doctorName: selectedDoctorName!,
                              query: queryController.text.trim(),
                              status: 'Pending',
                              createdAt: DateTime.now(),
                            );
                            setState(() {
                              leads.insert(0, localMock);
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lead saved locally (Backend Offline)'),
                                  backgroundColor: Color(0xFF2563EB),
                                ),
                              );
                            }
                          }
                          _fetchLeads();
                        },
                        child: const Text(
                          'Submit Escalation Lead',
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

  Future<void> markResolved(int index) async {
    final e = leads[index];
    try {
      await _apiService.updateLeadStatus(e.id, 'Resolved');
      setState(() {
        leads[index] = Lead(
          id: e.id,
          doctorName: e.doctorName,
          query: e.query,
          status: 'Resolved',
          assignedTo: e.assignedTo,
          createdAt: e.createdAt,
        );
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lead marked as Resolved!'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $err')),
        );
      }
    }
  }

  Future<void> assignTechnician(int index, String technician) async {
    final e = leads[index];
    try {
      await _apiService.updateLeadTechnician(e.id, technician);
      setState(() {
        leads[index] = Lead(
          id: e.id,
          doctorName: e.doctorName,
          query: e.query,
          status: 'In Progress',
          assignedTo: technician,
          createdAt: e.createdAt,
        );
      });
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning representative: $err')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String role = SessionState.getRole(user?.userMetadata);

    final isRep = role == 'Medical Representative';
    final isManager = role == 'Operations Manager';
    final isTech = role == 'Technician';

    final size = MediaQuery.of(context).size;
    final isWide = size.width > 960;

    final displayList = isTech
        ? leads.where((e) => e.assignedTo != null && e.assignedTo!.isNotEmpty).toList()
        : leads;

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
                          _buildHeroCard(leads),
                          const SizedBox(height: 24),
                          
                          // Leads Statistics Row
                          _buildLeadsStatsRow(),
                          const SizedBox(height: 24),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Pending Operations Pipeline',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMainColor,
                                ),
                              ),
                              if (isRep)
                                ElevatedButton.icon(
                                  onPressed: _showAddLeadDialog,
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: const Text('Register Lead'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEA580C),
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
                                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                                ))
                              : displayList.isEmpty
                                  ? _buildEmptyState()
                                  : _buildLeadsListView(displayList, isManager, isTech),
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
            'Escalation Leads Control',
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

  Widget _buildHeroCard(List<Lead> activeLeads) {
    final pendingCount = activeLeads.where((e) => e.status != 'Resolved').length;
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor], // Orange Gradient
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
              child: const Icon(Icons.star_rounded, size: 200, color: Colors.white),
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
                      'Team Diagnostic Pipeline',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    const Text(
                      'Distribute escalations to field technicians and track resolution status.',
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
                    'Active: $pendingCount',
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
          'Pipeline is empty. No active queries reported.',
          style: TextStyle(color: AppTheme.textMutedColor),
        ),
      ),
    );
  }

  Widget _buildLeadsListView(List<Lead> displayList, bool isManager, bool isTech) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final e = displayList[index];
        final isResolved = e.status == 'Resolved';

        Color badgeBg = const Color(0xFFECFDF5);
        Color badgeText = const Color(0xFF059669);
        if (e.status == 'Pending') {
          badgeBg = const Color(0xFFFEF2F2);
          badgeText = const Color(0xFFEF4444);
        } else if (e.status == 'In Progress') {
          badgeBg = const Color(0xFFFFFBEB);
          badgeText = const Color(0xFFD97706);
        }

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
                          radius: 16,
                          backgroundColor: const Color(0xFFFFF7ED),
                          child: const Icon(Icons.person_outline_rounded, color: Color(0xFFEA580C), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          e.doctorName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMainColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        e.status,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Query Description / Raised Interest:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  e.query,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(color: Color(0xFFF1F5F9), height: 1),
                const SizedBox(height: 16),
                
                // Bottom assign / resolution drawer row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: isResolved
                          ? Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: Color(0xFF059669), size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Resolved by: ${e.assignedTo ?? 'Field Rep'}',
                                  style: const TextStyle(
                                    color: Color(0xFF059669),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            )
                          : (isManager
                              ? Container(
                                  height: 40,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    borderRadius: BorderRadius.circular(10),
                                    color: const Color(0xFFF8FAFC),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: e.assignedTo,
                                      hint: const Text('Assign Field Representative', style: TextStyle(fontSize: 12)),
                                      isExpanded: true,
                                      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                                      items: availableTechnicians.map((String tech) {
                                        return DropdownMenuItem<String>(
                                          value: tech,
                                          child: Text(tech, style: const TextStyle(fontSize: 13)),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          final originalIndex = leads.indexOf(e);
                                          assignTechnician(originalIndex, val);
                                        }
                                      },
                                    ),
                                  ),
                                )
                              : Row(
                                  children: [
                                    const Icon(Icons.assignment_ind_outlined, color: Color(0xFF3B82F6), size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      e.assignedTo != null && e.assignedTo!.isNotEmpty
                                          ? 'Assigned to: ${e.assignedTo}'
                                          : 'Status: Unassigned',
                                      style: const TextStyle(
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )),
                    ),
                    const SizedBox(width: 16),
                    if (!isResolved && isTech)
                      ElevatedButton.icon(
                        onPressed: () {
                          final originalIndex = leads.indexOf(e);
                          markResolved(originalIndex);
                        },
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Resolve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 400.ms, delay: (index * 40).ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _buildLeadsStatsRow() {
    final totalCount = leads.length;
    final activeCount = leads.where((e) => e.status != 'Resolved').length;
    final resolvedCount = leads.where((e) => e.status == 'Resolved').length;

    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Total Leads',
            value: '$totalCount',
            icon: Icons.assignment_rounded,
            accentColor: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Active Leads',
            value: '$activeCount',
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFEA580C),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Resolved',
            value: '$resolvedCount',
            icon: Icons.task_alt_rounded,
            accentColor: const Color(0xFF16A34A),
          ),
        ),
      ],
    );
  }
}
