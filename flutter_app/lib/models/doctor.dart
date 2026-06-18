class Doctor {
  final String id;
  final String name;
  final String mobile;
  final String specialty;
  final String email;
  final String region; // Maps to Location
  final String address;
  final String status;
  final DateTime? scheduledTime;
  final String availableFrom;
  final String availableTo;
  final Map<String, String> customFields;

  Doctor({
    required this.id,
    required this.name,
    this.mobile = '',
    this.specialty = '',
    this.email = '',
    this.region = '',
    this.address = '',
    this.status = 'Saved',
    this.scheduledTime,
    this.availableFrom = '',
    this.availableTo = '',
    this.customFields = const {},
  });

  factory Doctor.fromMap(Map<String, dynamic> m) => Doctor(
        id: m['_id'] ?? m['id']?.toString() ?? '',
        name: m['name'] ?? '',
        mobile: m['mobile'] ?? '',
        specialty: m['specialty'] ?? '',
        email: m['email'] ?? m['emailId'] ?? '',
        region: m['region'] ?? m['location'] ?? '',
        address: m['address'] ?? '',
        status: m['status'] ?? 'Saved',
        scheduledTime: m['scheduledTime'] != null
            ? DateTime.tryParse(m['scheduledTime'])
            : (m['scheduled_time'] != null ? DateTime.tryParse(m['scheduled_time']) : null),
        availableFrom: m['availableFrom'] ?? m['available_from'] ?? '',
        availableTo: m['availableTo'] ?? m['available_to'] ?? '',
        customFields: m['customFields'] != null
            ? Map<String, String>.from(m['customFields'])
            : (m['custom_fields'] != null
                ? Map<String, String>.from(m['custom_fields'])
                : const {}),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'mobile': mobile,
        'specialty': specialty,
        'email': email,
        'region': region,
        'address': address,
        'status': status,
        'scheduledTime': scheduledTime?.toIso8601String(),
        'availableFrom': availableFrom,
        'availableTo': availableTo,
        'customFields': customFields,
      };
}
