class Escalation {
  final String id;
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
      id: m['_id'] ?? m['id']?.toString() ?? '',
      doctorName: m['doctor_name'] ?? '',
      query: m['query'] ?? '',
      status: m['status'] ?? '',
      assignedTo: m['assigned_to'],
      createdAt: m['created_at'] != null 
          ? DateTime.tryParse(m['created_at']) 
          : (m['createdAt'] != null ? DateTime.tryParse(m['createdAt']) : null),
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
