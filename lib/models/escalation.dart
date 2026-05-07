class Escalation {
  final int id;
  final String doctorName;
  final String query;
  final String status;
  final String? assignedTo;
  final DateTime? createdAt;

  Escalation({
    required this.id,
    required this.doctorName,
    required this.query,
    required this.status,
    this.assignedTo,
    this.createdAt,
  });

  factory Escalation.fromMap(Map<String, dynamic> m) {
    return Escalation(
      id: m['id'] is int ? m['id'] : int.parse('${m['id']}'),
      doctorName: m['doctor_name'] ?? '',
      query: m['query'] ?? '',
      status: m['status'] ?? '',
      assignedTo: m['assigned_to'],
      createdAt: m['created_at'] != null ? DateTime.parse(m['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'doctor_name': doctorName,
        'query': query,
        'status': status,
        'assigned_to': assignedTo,
        'created_at': createdAt?.toIso8601String(),
      };
}
