class Doctor {
  final String id;
  final String name;
  final String specialty;
  final String region;

  Doctor({required this.id, required this.name, required this.specialty, required this.region});

  factory Doctor.fromMap(Map<String, dynamic> m) => Doctor(
        id: m['_id'] ?? m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        specialty: m['specialty'] ?? '',
        region: m['region'] ?? '',
      );
}
