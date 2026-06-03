import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/sidebar.dart';
import '../../services/api_service.dart';
import '../../models/doctor.dart';
import '../../models/interaction.dart';

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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
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
          // Toggle button to learn both views
          IconButton(
            icon: Icon(
              showAsTable ? Icons.view_list_rounded : Icons.table_chart_rounded,
            ),
            tooltip: showAsTable
                ? 'Switch to List View'
                : 'Switch to Table View',
            onPressed: () {
              setState(() {
                showAsTable = !showAsTable;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const Sidebar(),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
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
                          'Analytics',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Track performance and interactions.',
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
                        'Total: ${doctorData.length}',
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

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : doctorData.isEmpty
                      ? const Center(child: Text('No doctors found.'))
                      : showAsTable
                          ? _buildTableView()
                                .animate()
                                .fade(duration: 400.ms)
                                .slideX(begin: 0.05)
                          : _buildListView()
                                .animate()
                                .fade(duration: 400.ms)
                                .slideX(begin: 0.05),
            ),
          ].animate(interval: 50.ms).fade(duration: 400.ms),
        ),
      ),
    );
  }

  // 1. Learning DataTable feature
  Widget _buildTableView() {
    return Card(
      elevation: 4,
      shadowColor: Colors.blueAccent.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.blueAccent.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: WidgetStateProperty.resolveWith(
                (states) => Colors.grey[100],
              ),
              headingTextStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              dataRowMinHeight: 60,
              dataRowMaxHeight: 60,
              columns: const [
                DataColumn(label: Text('Doctor')),
                DataColumn(label: Text('Specialty')),
                DataColumn(label: Text('Region')),
                DataColumn(label: Text('Interactions'), numeric: true),
              ],
              rows: doctorData.map((data) {
                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child:
                                const Icon(
                                      Icons.person,
                                      size: 18,
                                      color: Colors.blueAccent,
                                    )
                                    .animate(
                                      onPlay: (controller) =>
                                          controller.repeat(reverse: true),
                                    )
                                    .scale(
                                      begin: const Offset(1, 1),
                                      end: const Offset(1.1, 1.1),
                                      duration: 1.seconds,
                                    )
                                    .shimmer(
                                      duration: 2.seconds,
                                      color: Colors.blue[300],
                                    ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                          data.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(data.specialty)),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        data.region,
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                  // Highlighting High performers
                  DataCell(
                    Text(
                      _getInteractionCountForDoctor(data.id).toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // 2. Learning ListView.builder feature
  Widget _buildListView() {
    return ListView.builder(
      itemCount: doctorData.length,
      itemBuilder: (context, index) {
        final data = doctorData[index];
        return Card(
              elevation: 4,
              shadowColor: Colors.blueAccent.withOpacity(0.1),
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blueAccent.withOpacity(0.05)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child:
                          const Icon(
                                Icons.medical_services_rounded,
                                color: Colors.blueAccent,
                              )
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .scale(
                                begin: const Offset(1, 1),
                                end: const Offset(1.1, 1.1),
                                duration: 1200.ms,
                              )
                              .shimmer(
                                duration: 2.seconds,
                                color: Colors.blue[300],
                              ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${data.specialty} • ${data.region}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blueAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.2),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                _getInteractionCountForDoctor(data.id).toString(),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                              Text(
                                'Visits',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                        .animate(onPlay: (controller) => controller.repeat())
                        .shimmer(
                          duration: 2500.ms,
                          color: Colors.white24,
                          angle: 0.5,
                        ),
                  ],
                ),
              ),
            )
            .animate()
            .fade(duration: 400.ms, delay: (50 * index).ms)
            .slideX(begin: 0.1);
      },
    );
  }
}
