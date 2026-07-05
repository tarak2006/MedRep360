import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/session_state.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/doctors/doctors_page.dart';
import '../features/doctors/doctor_onboarding_page.dart';
import '../features/leads/leads_page.dart';
import '../features/interactions/interactions_page.dart';
import '../theme_config.dart';

class Sidebar extends StatelessWidget {
  final bool isPermanent;
  const Sidebar({super.key, this.isPermanent = false});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final String name = SessionState.getName(user?.userMetadata);
    final String role = SessionState.getRole(user?.userMetadata);
    final currentRoute = ModalRoute.of(context)?.settings.name;

    final isRep = role == 'Medical Representative';
    final isManager = role == 'Operations Manager';

    // Widget content builder
    Widget sidebarContent(BuildContext context) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.surfaceColor, AppTheme.backgroundColor], // Premium dark gradient
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            right: BorderSide(color: AppTheme.hairlineColor),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sidebar Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/images/logo_icon.png',
                        width: 28,
                        height: 28,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.monitor_heart_rounded,
                          color: AppTheme.primaryColor,
                          size: 28,
                        ),
                      ),
                    ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MedRep 360',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Clinical Workspace',
                            style: TextStyle(
                              color: AppTheme.textSubtleColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Divider(color: AppTheme.hairlineColor, height: 1),
              const SizedBox(height: 24),
              
              // Navigation Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildNavItem(
                      context,
                      icon: Icons.grid_view_rounded,
                      title: 'Dashboard',
                      isActive: currentRoute == '/dashboard' || currentRoute == null,
                      onTap: () {
                        if (currentRoute != '/dashboard') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardPage(),
                              settings: const RouteSettings(name: '/dashboard'),
                            ),
                          );
                        }
                      },
                    ),
                    if (isRep || isManager) ...[
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.bar_chart_rounded,
                        title: 'Analytics',
                        isActive: currentRoute == '/analytics',
                        onTap: () {
                          if (currentRoute != '/analytics') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DoctorsPage(),
                                settings: const RouteSettings(name: '/analytics'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.person_add_alt_1_rounded,
                        title: 'Onboarding',
                        isActive: currentRoute == '/onboarding',
                        onTap: () {
                          if (currentRoute != '/onboarding') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DoctorOnboardingPage(),
                                settings: const RouteSettings(name: '/onboarding'),
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      _buildNavItem(
                        context,
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Interactions',
                        isActive: currentRoute == '/interactions',
                        onTap: () {
                          if (currentRoute != '/interactions') {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const InteractionsPage(),
                                settings: const RouteSettings(name: '/interactions'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildNavItem(
                      context,
                      icon: Icons.star_rounded,
                      title: 'Leads Portal',
                      isActive: currentRoute == '/leads',
                      onTap: () {
                        if (currentRoute != '/leads') {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LeadsPage(),
                              settings: const RouteSettings(name: '/leads'),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              
              // User profile & logout section
              Divider(color: AppTheme.hairlineColor, height: 1),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryColor,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: AppTheme.textMainColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                role,
                                style: const TextStyle(
                                  color: AppTheme.textSubtleColor,
                                  fontSize: 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildNavItem(
                      context,
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      isActive: false,
                      isDestructive: true,
                      onTap: () {
                        SessionState.clear();
                        Navigator.pushReplacementNamed(context, '/');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isPermanent) {
      return SizedBox(
        width: 280,
        child: sidebarContent(context),
      );
    }

    return Drawer(
      child: sidebarContent(context),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isActive,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final activeColor = AppTheme.primaryColor;
    final inactiveColor = AppTheme.textMutedColor;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryColor.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isActive ? Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 1) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isDestructive
                      ? Colors.redAccent
                      : (isActive ? activeColor : inactiveColor),
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? Colors.redAccent
                          : (isActive ? activeColor : inactiveColor),
                      fontSize: 14,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
                if (isActive)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
