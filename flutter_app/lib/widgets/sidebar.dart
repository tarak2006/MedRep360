import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_state.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/doctors/doctors_page.dart';
import '../features/doctors/doctor_onboarding_page.dart';
import '../features/leads/leads_page.dart';
import '../features/interactions/interactions_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String name = SessionState.getName(user?.userMetadata);
    final String role = SessionState.getRole(user?.userMetadata);

    final isRep = role == 'Medical Representative';
    final isManager = role == 'Operations Manager';

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blueAccent,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.monitor_heart, size: 40, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
                    .shimmer(duration: 2.seconds, color: Colors.white),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  role,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // Dashboard (Available for all)
          ListTile(
            leading: const Icon(Icons.dashboard_rounded),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardPage()),
              );
            },
          ),

          // Analytics (Available for Reps and Managers)
          if (isRep || isManager)
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorsPage()),
                );
              },
            ),

          // Onboarding (Available for Reps and Managers)
          if (isRep || isManager)
            ListTile(
              leading: const Icon(Icons.person_add_rounded),
              title: const Text('Onboarding'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorOnboardingPage()),
                );
              },
            ),

          // Interactions (Available for Reps and Managers)
          if (isRep || isManager)
            ListTile(
              leading: const Icon(Icons.forum_rounded),
              title: const Text('Interactions'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const InteractionsPage()),
                );
              },
            ),

          // Leads (Available for all roles)
          ListTile(
            leading: const Icon(Icons.star_rounded),
            title: const Text('Leads'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LeadsPage()),
              );
            },
          ),

          const Divider(),
          
          // Logout (Available for all)
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              SessionState.clear();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ].animate(interval: 50.ms).fade(duration: 400.ms).slideX(begin: -0.1),
      ),
    );
  }
}


