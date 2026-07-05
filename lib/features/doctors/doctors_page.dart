import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/dashboard_card.dart';
import '../../services/api_service.dart';
import '../../models/doctor.dart';
import '../../models/interaction.dart';
import '../../theme_config.dart';

class DoctorsPage extends StatefulWidget {
  const DoctorsPage({super.key});

  @override
  State<DoctorsPage> createState() => _DoctorsPageState();
}

class _DoctorsPageState extends State<DoctorsPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<Doctor> doctorData = [];
  List<Interaction> interactionsData = [];
  bool showAsTable = true;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  Future<void> _fetchDoctors() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _apiService.fetchDoctors(),
        _apiService.fetchInteractions(),
      ]);
      setState(() {
        doctorData = futures[0] as List<Doctor>;
        interactionsData = futures[1] as List<Interaction>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  int _getInteractionCountForDoctor(String doctorId) {
    return interactionsData.where((i) => i.doctorId == doctorId).length;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 960;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      drawer: isWide ? null : const Sidebar(),
      body: Row(
        children: [
          // Sidebar Panel on desktop
          if (isWide)
            const Sidebar(isPermanent: true),
            
          // Main Content
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  // App Bar
                  _buildAppBar(context),
                  
                  // Main Body Scrollable
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Analytics Card
                          _buildHeroCard(),
                          const SizedBox(height: 24),
                          
                          // Analytics Mini Stats Row
                          _buildAnalyticsStatsRow(),
                          const SizedBox(height: 24),
                          
                          // Toggle header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Portfolio Distribution',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textMainColor,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.hairlineColor),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    showAsTable ? Icons.view_list_rounded : Icons.table_chart_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                  tooltip: showAsTable ? 'Switch to Card List' : 'Switch to Table View',
                                  onPressed: () {
                                    setState(() {
                                      showAsTable = !showAsTable;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Inner View
                          _isLoading
                              ? const Center(child: Padding(
                                  padding: EdgeInsets.all(40.0),
                                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                                ))
                              : doctorData.isEmpty
                                  ? const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(40.0),
                                        child: Text('No doctor profiles found.'),
                                      ),
                                    )
                                  : showAsTable
                                      ? _buildTableView().animate().fade().slideY(begin: 0.05)
                                      : _buildListView().animate().fade().slideY(begin: 0.05),
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
            'Doctor Analytics & Metrics',
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
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor], // Darker rich blue gradient
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
              child: const Icon(Icons.analytics_rounded, size: 200, color: Colors.white),
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
                      'Analytics & Performance',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -0.5),
                    ).animate().fade().slideY(begin: 0.1),
                    const SizedBox(height: 6),
                    const Text(
                      'Track interactive consultation loops and communication targets.',
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
                    'Total Accounts: ${doctorData.length}',
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

  Widget _buildTableView() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.hairlineColor),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.01),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.resolveWith(
            (states) => AppTheme.surfaceColorLevel2,
          ),
          headingTextStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textMainColor,
            fontSize: 13,
          ),
          horizontalMargin: 20,
          columnSpacing: 36,
          dataRowMinHeight: 60,
          dataRowMaxHeight: 60,
          columns: const [
            DataColumn(label: Text('Doctor Name')),
            DataColumn(label: Text('Specialty')),
            DataColumn(label: Text('Region')),
            DataColumn(label: Text('Interactions'), numeric: true),
            DataColumn(label: Text('Status')),
          ],
          rows: doctorData.map((doc) {
            final count = _getInteractionCountForDoctor(doc.id);
            
            // Build nice status badge colors
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

            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                        child: Text(
                          doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        doc.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMainColor),
                      ),
                    ],
                  ),
                ),
                DataCell(Text(doc.specialty, style: const TextStyle(fontSize: 13))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColorLevel2,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      doc.region.isNotEmpty ? doc.region : 'Not Specified',
                      style: const TextStyle(color: AppTheme.textMutedColor, fontSize: 11),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    '$count',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMainColor),
                  ),
                ),
                DataCell(
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
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: doctorData.length,
      itemBuilder: (context, index) {
        final doc = doctorData[index];
        final count = _getInteractionCountForDoctor(doc.id);
        
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                  child: Text(
                    doc.name.isNotEmpty ? doc.name[0].toUpperCase() : 'D',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            doc.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMainColor),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              doc.status,
                              style: TextStyle(color: badgeText, fontWeight: FontWeight.bold, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${doc.specialty} • ${doc.region.isNotEmpty ? doc.region : "Global"}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$count',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                      ),
                      const Text(
                        'Visits',
                        style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fade(duration: 350.ms, delay: (index * 40).ms).slideX(begin: 0.05);
      },
    );
  }

  Widget _buildAnalyticsStatsRow() {
    final activeLoops = doctorData.where((d) => d.status != 'Saved').length;
    final totalInteractions = interactionsData.length;
    final avgInteractions = doctorData.isEmpty 
        ? '0.0' 
        : (totalInteractions / doctorData.length).toStringAsFixed(1);

    return Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Active Loops',
            value: '$activeLoops',
            icon: Icons.bolt_rounded,
            accentColor: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Logged Syncs',
            value: '$totalInteractions',
            icon: Icons.chat_bubble_outline_rounded,
            accentColor: const Color(0xFF0D9488),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: DashboardCard(
            title: 'Avg. Interactions',
            value: avgInteractions,
            icon: Icons.analytics_rounded,
            accentColor: const Color(0xFFEA580C),
          ),
        ),
      ],
    );
  }
}
