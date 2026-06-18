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
import '../interactions/interactions_page.dart';

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

  String _getDoctorName(String doctorId) {
    final doc = _doctors.where((d) => d.id == doctorId).firstOrNull;
    return doc?.name ?? 'Unknown Doctor';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('MedRep 360')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final user = Supabase.instance.client.auth.currentUser;
    final String name = SessionState.getName(user?.userMetadata);
    final String role = SessionState.getRole(user?.userMetadata);

    final isRep = role == 'Medical Representative';
    final isManager = role == 'Operations Manager';
    final isTech = role == 'Technician';

    // Prepare recent activities based on role
    final List<Map<String, dynamic>> recentActivities = [];

    if (isRep || isManager) {
      recentActivities.addAll(_interactions.map((i) {
        final docName = i.doctorName.isNotEmpty ? i.doctorName : _getDoctorName(i.doctorId);
        return {
          'doctor': docName,
          'action': 'Interaction: ${i.notes}',
          'time': i.date != null ? i.date!.toLocal().toString().substring(0, 10) : 'Recent',
          'icon': Icons.chat_bubble_outline,
          'color': Colors.blue
        };
      }));
    }

    if (isManager || isTech) {
      final relevantLeads = isTech
          ? _leads.where((e) => e.assignedTo != null && e.assignedTo!.isNotEmpty)
          : _leads;

      recentActivities.addAll(relevantLeads.map((e) {
        return {
          'doctor': e.doctorName,
          'action': 'Lead: ${e.status}',
          'time': e.createdAt != null ? e.createdAt!.toLocal().toString().substring(0, 10) : 'Recent',
          'icon': e.status == 'Resolved' ? Icons.check_circle_outline : Icons.warning_amber_rounded,
          'color': e.status == 'Resolved' ? Colors.green : Colors.orange
        };
      }));
    }


    return Scaffold(
      backgroundColor: Colors.grey[50], // Professional light background
      appBar: AppBar(
        title: const Text('MedRep 360', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        centerTitle: false,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () {
               // Dummy log out back to login
               Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const Sidebar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image Section
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [Colors.blueAccent.withOpacity(0.9), Colors.transparent],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  )
                ),
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $name',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ).animate().fade().slideY(begin: 0.3),
                    const SizedBox(height: 8),
                    Text(
                      'Logged in as $role • medrep360 workspace',
                      style: const TextStyle(fontSize: 16, color: Colors.white70),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.3),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Grid of Stats Cards
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth > 1000 ? 4 : constraints.maxWidth > 600 ? 2 : 1;
                
                final List<Widget> cards = [];

                if (isRep || isManager) {
                  cards.add(
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const DoctorsPage()),
                        );
                      },
                      child: DashboardCard(
                        title: 'Total Doctors',
                        value: '${_doctors.length}',
                        icon: Icons.personal_injury_rounded,
                      ),
                    ),
                  );
                  cards.add(
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const InteractionsPage()),
                        );
                      },
                      child: DashboardCard(
                        title: 'Total Interactions',
                        value: '${_interactions.length}',
                        icon: Icons.forum_rounded,
                      ),
                    ),
                  );
                }

                if (isManager || isTech) {
                  final relevantLeads = isTech
                      ? _leads.where((e) => e.assignedTo != null && e.assignedTo!.isNotEmpty).toList()
                      : _leads;

                  cards.add(
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LeadsPage()),
                        );
                      },
                      child: DashboardCard(
                        title: isTech ? 'My Pending Issues' : 'Pending Leads',
                        value: '${relevantLeads.where((e) => e.status != 'Resolved').length}',
                        icon: Icons.warning_rounded,
                      ),
                    ),
                  );
                  cards.add(
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const LeadsPage()),
                        );
                      },
                      child: DashboardCard(
                        title: isTech ? 'My Resolved Issues' : 'Resolved Leads',
                        value: '${relevantLeads.where((e) => e.status == 'Resolved').length}',
                        icon: Icons.task_alt_rounded,
                      ),
                    ),
                  );
                }

                return GridView.count(
                  crossAxisCount: crossAxisCount > cards.length ? cards.length : crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 800 ? 2.0 : 2.4, 
                  children: cards.animate(interval: 100.ms).fade(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
                );
              }
            ),
            
            const SizedBox(height: 36),

            
            // Recent Activity Section
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            
            // List of Recent Activities using ListView within a Card
            Card(
              elevation: 4,
              shadowColor: Colors.blueAccent.withOpacity(0.1),
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.blueAccent.withOpacity(0.05)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentActivities.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final activity = recentActivities[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (activity['color'] as Color).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(activity['icon'] as IconData, color: activity['color'] as Color)
                          .animate(onPlay: (controller) => controller.repeat(reverse: true))
                          .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
                          .shimmer(duration: 2.seconds, color: (activity['color'] as Color).withOpacity(0.5)),
                    ),
                    title: Text(
                      activity['doctor'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        activity['action'] as String,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                    trailing: Text(
                      activity['time'] as String,
                      style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    onTap: () {},
                  );
                },
              ).animate().fade(duration: 600.ms, delay: 300.ms).slideY(begin: 0.1),
            ),
          ].animate(interval: 100.ms).fade(duration: 400.ms),
        ),
      ),
    );
  }
}