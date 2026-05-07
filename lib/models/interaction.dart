class Interaction {
  final int id;
  final int doctorId;
  final String query;
  final String response;
  final DateTime? timestamp;

  Interaction({
    required this.id,
    required this.doctorId,
    required this.query,
    required this.response,
    this.timestamp,
  });

  factory Interaction.fromMap(Map<String, dynamic> m) => Interaction(
        id: m['id'] is int ? m['id'] : int.parse('${m['id']}'),
        doctorId: m['doctor_id'] is int ? m['doctor_id'] : int.parse('${m['doctor_id']}'),
        query: m['query'] ?? '',
        response: m['response'] ?? '',
        timestamp: m['timestamp'] != null ? DateTime.parse(m['timestamp']) : null,
      );
}
