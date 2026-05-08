import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/sidebar.dart';
import '../../services/supabase_service.dart';
import '../../models/escalation.dart';
import '../../models/interaction.dart';
import '../../models/doctor.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;

  List<Escalation> _escalations = [];
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
        _supabaseService.fetchEscalations(),
        _supabaseService.fetchInteractions(),
        _supabaseService.fetchDoctors(),
      ]);
      setState(() {
        _escalations = futures[0] as List<Escalation>;
        _interactions = futures[1] as List<Interaction>;
        _doctors = futures[2] as List<Doctor>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _getDoctorName(int doctorId) {
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

    // Prepare recent activities from interactions
    final recentActivities = _interactions.map((i) {
      return {
        'doctor': _getDoctorName(i.doctorId),
        'action': 'Interaction: ${i.query}',
        'time': i.timestamp?.toString().substring(0, 10) ?? 'Recent',
        'icon': Icons.chat_bubble_outline,
        'color': Colors.blue
      };
    }).toList();

    // Adding some escalations as recent activities too
    final escalationActivities = _escalations.map((e) {
      return {
        'doctor': e.doctorName,
        'action': 'Escalation: ${e.status}',
        'time': e.createdAt?.toString().substring(0, 10) ?? 'Recent',
        'icon': e.status == 'Resolved' ? Icons.check_circle_outline : Icons.warning_amber_rounded,
        'color': e.status == 'Resolved' ? Colors.green : Colors.orange
      };
    });
    
    recentActivities.addAll(escalationActivities);
    // Sort logic could be added here if timestamp is reliable


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
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1551076805-e18690c5e53b?q=80&w=2000&auto=format&fit=crop'),
                  fit: BoxFit.cover,
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
                    const Text(
                      'Welcome to MedRep 360',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white),
                    ).animate().fade().slideY(begin: 0.3),
                    const SizedBox(height: 8),
                    const Text(
                      'Your comprehensive dashboard for medical representative operations.',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
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
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: constraints.maxWidth > 800 ? 2.8 : 3.0, 
                  children: [
                    DashboardCard(
                      title: 'Total Doctors',
                      value: '${_doctors.length}',
                      icon: Icons.personal_injury_rounded,
                    ),
                    DashboardCard(
                      title: 'Total Interactions',
                      value: '${_interactions.length}',
                      icon: Icons.forum_rounded,
                    ),
                    DashboardCard(
                      title: 'Pending Escalations',
                      value: '${_escalations.where((e) => e.status != 'Resolved').length}',
                      icon: Icons.warning_rounded,
                    ),
                    DashboardCard(
                      title: 'Resolved',
                      value: '${_escalations.where((e) => e.status == 'Resolved').length}',
                      icon: Icons.task_alt_rounded,
                    ),
                  ].animate(interval: 100.ms).fade(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
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