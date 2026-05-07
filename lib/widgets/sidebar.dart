import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/doctors/doctors_page.dart';
import '../features/escalations/escalations_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
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
                const Icon(Icons.monitor_heart, size: 48, color: Colors.white)
                    .animate(onPlay: (controller) => controller.repeat(reverse: true))
                    .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
                    .shimmer(duration: 2.seconds, color: Colors.white),
                const SizedBox(height: 12),
                const Text('MedRep 360', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
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
          ListTile(
            leading: const Icon(Icons.people_alt_rounded),
            title: const Text('Doctor Analytics'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DoctorsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.priority_high_rounded),
            title: const Text('Escalations'),
            onTap: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const EscalationsPage()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ].animate(interval: 50.ms).fade(duration: 400.ms).slideX(begin: -0.1),
      ),
    );
  }
}
