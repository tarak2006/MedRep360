import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/sidebar.dart';
import '../../models/escalation.dart';
import '../../services/supabase_service.dart';

class EscalationsPage extends StatefulWidget {
  const EscalationsPage({super.key});

  @override
  State<EscalationsPage> createState() => _EscalationsPageState();
}

class _EscalationsPageState extends State<EscalationsPage> {
  bool _isLoading = true;
  List<Escalation> escalations = [];
  final SupabaseService _supabaseService = SupabaseService();
  final List<String> availableTechnicians = [
    'Tech Alex',
    'Tech Sarah',
    'Tech Rahul',
    'Tech Mike',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEscalations();
  }

  Future<void> _fetchEscalations() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabaseService.fetchEscalations();
      setState(() {
        escalations = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching escalations: $e')),
        );
      }
    }
  }

  Future<void> markResolved(int index) async {
    final e = escalations[index];
    try {
      await _supabaseService.updateEscalationStatus(e.id, 'Resolved');
      setState(() {
        escalations[index] = Escalation(
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
          const SnackBar(content: Text('Escalation marked as Resolved!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> assignTechnician(int index, String technician) async {
    final e = escalations[index];
    try {
      await _supabaseService.updateEscalationTechnician(e.id, technician);
      setState(() {
        escalations[index] = Escalation(
          id: e.id,
          doctorName: e.doctorName,
          query: e.query,
          status: 'In Progress',
          assignedTo: technician,
          createdAt: e.createdAt,
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error assigning technician: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Escalation Management',
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
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1551076805-e18690c5e53b?q=80&w=2000&auto=format&fit=crop',
                  ),
                  fit: BoxFit.cover,
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
                      Colors.orange.shade800.withOpacity(0.9),
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
                          'Active Escalations',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ).animate().fade().slideY(begin: 0.3),
                        const SizedBox(height: 8),
                        const Text(
                          'Manage and resolve pending issues swiftly.',
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
                        'Pending: ${escalations.where((e) => e.status != 'Resolved').length}',
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

            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (escalations.isEmpty)
              const Expanded(
                child: Center(child: Text('No escalations found.')),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: escalations.length,
                  itemBuilder: (context, index) {
                    final e = escalations[index];
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: Colors.blueAccent
                                              .withOpacity(0.1),
                                          child:
                                              const Icon(
                                                    Icons.person,
                                                    color: Colors.blueAccent,
                                                  )
                                                  .animate(
                                                    onPlay: (controller) =>
                                                        controller.repeat(
                                                          reverse: true,
                                                        ),
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
                                                  : Colors.orange.withOpacity(
                                                      0.1,
                                                    )),
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
                                  'Query Issue:',
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Assign technician dropdown
                                    Expanded(
                                      child: isResolved
                                          ? Text(
                                              'Handled by: ${e.assignedTo ?? 'Unknown'}',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            )
                                          : Container(
                                              height: 45,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: DropdownButtonHideUnderline(
                                                child: DropdownButton<String>(
                                                  value: e.assignedTo,
                                                  hint: const Text(
                                                    'Assign Technician',
                                                  ),
                                                  isExpanded: true,
                                                  icon: const Icon(
                                                    Icons.engineering_rounded,
                                                  ),
                                                  items: availableTechnicians
                                                      .map((String tech) {
                                                        return DropdownMenuItem<
                                                          String
                                                        >(
                                                          value: tech,
                                                          child: Text(tech),
                                                        );
                                                      })
                                                      .toList(),
                                                  onChanged: (val) {
                                                    if (val != null)
                                                      assignTechnician(
                                                        index,
                                                        val,
                                                      );
                                                  },
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Resolve Button
                                    if (!isResolved)
                                      ElevatedButton.icon(
                                            onPressed: () =>
                                                markResolved(index),
                                            icon: const Icon(
                                              Icons.check_circle_outline,
                                            ),
                                            label: const Text('Resolve'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              elevation: 4,
                                              shadowColor: Colors.green
                                                  .withOpacity(0.4),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          )
                                          .animate(
                                            onPlay: (controller) =>
                                                controller.repeat(),
                                          )
                                          .shimmer(
                                            duration: 2500.ms,
                                            color: Colors.white30,
                                            angle: 0.5,
                                          ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                        .animate()
                        .fade(duration: 400.ms, delay: (50 * index).ms)
                        .slideY(begin: 0.1);
                  },
                ),
              ),
          ].animate(interval: 50.ms).fade(duration: 400.ms),
        ),
      ),
    );
  }
}
