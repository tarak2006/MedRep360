class Interaction {
  final String id;
  final String doctorId;
  final String doctorName;
  final String notes;
  final String type;
  final DateTime? date;

  Interaction({
    required this.id,
    required this.doctorId,
    required this.doctorName,
    required this.notes,
    required this.type,
    this.date,
  });

  factory Interaction.fromMap(Map<String, dynamic> m) {
    String docId = '';
    String docName = '';
    
    if (m['doctor'] is Map) {
      final docMap = m['doctor'] as Map<String, dynamic>;
      docId = docMap['_id'] ?? docMap['id']?.toString() ?? '';
      docName = docMap['name'] ?? '';
    } else {
      docId = m['doctor']?.toString() ?? m['doctor_id']?.toString() ?? '';
    }

    return Interaction(
      id: m['_id'] ?? m['id']?.toString() ?? '',
      doctorId: docId,
      doctorName: docName,
      notes: m['notes'] ?? m['query'] ?? '',
      type: m['type'] ?? m['response'] ?? 'In-person',
      date: m['date'] != null 
          ? DateTime.tryParse(m['date']) 
          : (m['timestamp'] != null ? DateTime.tryParse(m['timestamp']) : null),
    );
  }
}

