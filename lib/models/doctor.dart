class Doctor {
  final int id;
  final String name;
  final String specialty;
  final String region;

  Doctor({required this.id, required this.name, required this.specialty, required this.region});

  factory Doctor.fromMap(Map<String, dynamic> m) => Doctor(
        id: m['id'] is int ? m['id'] : int.parse('${m['id']}'),
        name: m['name'] ?? '',
        specialty: m['specialty'] ?? '',
        region: m['region'] ?? '',
      );
}
