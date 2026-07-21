import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/sidebar.dart';
import '../../models/lead.dart';
import '../../models/doctor.dart';
import '../../services/api_service.dart';
import '../../services/session_state.dart';
import '../admin/admin_panel_page.dart';

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
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 16),
                    
                    const Text(
                      'Select Doctor',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(10),
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
                      'Interest Details / Query',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: queryController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe the doctor\'s query or interest raised...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lead registered successfully!')),
                            );
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lead saved locally (Backend Offline)')),
                            );
                          }
                          _fetchLeads();
                        },
                        child: const Text(
                          'Submit Lead',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          const SnackBar(content: Text('Lead marked as Resolved!')),
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
          SnackBar(content: Text('Error assigning technician: $err')),
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

    final displayList = isTech
        ? leads.where((e) => e.assignedTo != null && e.assignedTo!.isNotEmpty).toList()
        : leads;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Leads Management',
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
                  colors: [Color(0xFFE65100), Color(0xFFF57C00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orangeAccent.withOpacity(0.3),
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
                      Colors.orange.shade800.withOpacity(0.4),
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
                          'Active Leads',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Track interest and potential queries from interaction processes.',
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
                        'Active: ${leads.where((e) => e.status != 'Resolved').length}',
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

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Leads List',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdminPanelPage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.cloud_upload_rounded),
                      label: const Text('Admin Panel (Data Ingestion)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (isRep)
                      ElevatedButton.icon(
                        onPressed: _showAddLeadDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Register Lead'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (displayList.isEmpty)
              const Expanded(
                child: Center(child: Text('No leads found.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: displayList.length,
                  itemBuilder: (context, index) {
                    final e = displayList[index];
                    final isResolved = e.status == 'Resolved';

                    return Card(
                      elevation: 4,
                      shadowColor: Colors.blueAccent.withOpacity(0.1),
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.blueAccent.withOpacity(0.05),
                        ),
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
                                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.blueAccent,
                                      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                       .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1.seconds)
                                       .shimmer(duration: 2.seconds, color: Colors.blue[300]),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      e.doctorName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isResolved
                                        ? Colors.green.withOpacity(0.1)
                                        : (e.status == 'Pending'
                                            ? Colors.red.withOpacity(0.1)
                                            : Colors.orange.withOpacity(0.1)),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    e.status,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isResolved
                                          ? Colors.green
                                          : (e.status == 'Pending'
                                              ? Colors.red
                                              : Colors.orange),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Query / Interest Raised:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              e.query,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Bottom Actions Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Assign technician dropdown or label
                                Expanded(
                                  child: isResolved
                                      ? Text(
                                          'Handled by: ${e.assignedTo ?? 'Unknown'}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : (isManager
                                          ? Container(
                                              height: 45,
                                              padding: const EdgeInsets.symmetric(horizontal: 12),
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey.shade300),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: e.assignedTo,
                                                  hint: const Text('Assign Representative'),
                                                  isExpanded: true,
                                                  icon: const Icon(Icons.engineering_rounded),
                                                  items: availableTechnicians.map((String tech) {
                                                    return DropdownMenuItem<String>(
                                                      value: tech,
                                                      child: Text(tech),
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
                                          : Text(
                                              e.assignedTo != null && e.assignedTo!.isNotEmpty
                                                  ? 'Assigned to: ${e.assignedTo}'
                                                  : 'Assigned to: Not Assigned',
                                              style: const TextStyle(
                                                color: Colors.blueAccent,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )),
                                ),
                                const SizedBox(width: 16),
                                // Resolve Button (Only visible to Technicians)
                                if (!isResolved && isTech)
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      final originalIndex = leads.indexOf(e);
                                      markResolved(originalIndex);
                                    },
                                    icon: const Icon(
                                      Icons.check_circle_outline,
                                    ),
                                    label: const Text('Resolve'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      elevation: 4,
                                      shadowColor: Colors.green.withOpacity(0.4),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fade(duration: 400.ms, delay: (50 * index).ms).slideY(begin: 0.1);
                  },
                ),
              ),
          ].animate(interval: 50.ms).fade(duration: 400.ms),
        ),
      ),
    );
  }
}
