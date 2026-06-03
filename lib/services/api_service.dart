import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/lead.dart';
import '../models/interaction.dart';
import '../models/doctor.dart';

class ApiService {
  final String baseUrl = kReleaseMode
      ? 'https://medrep360-backend-599554914298.asia-south1.run.app/api'
      : 'http://localhost:5000/api';

  Future<List<Lead>> fetchLeads() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/leads'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Lead.fromMap(e)).toList();
      } else {
        return _getDummyLeads();
      }
    } catch (e) {
      return _getDummyLeads();
    }
  }

  Future<Lead?> createLead(Map<String, dynamic> leadData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/leads'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(leadData),
      );
      if (res.statusCode == 201) {
        return Lead.fromMap(json.decode(res.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<Lead> _getDummyLeads() {
    return [
      Lead(
        id: '1',
        doctorName: 'Dr. Alice Smith',
        query: 'Requested samples of Paracetamol 500mg but only received 250mg.',
        status: 'Pending',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Lead(
        id: '2',
        doctorName: 'Dr. Bob Jones',
        query: 'The login credentials for the portal are not working.',
        status: 'In Progress',
        assignedTo: 'Tech Alex',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<void> updateLeadStatus(String id, String status) async {
    await http.put(
      Uri.parse('$baseUrl/leads/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'status': status}),
    );
  }

  Future<void> updateLeadTechnician(String id, String technician) async {
    await http.put(
      Uri.parse('$baseUrl/leads/$id'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'assigned_to': technician, 'status': 'In Progress'}),
    );
  }

  Future<List<Interaction>> fetchInteractions() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/interactions'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Interaction.fromMap(e)).toList();
      } else {
        return _getDummyInteractions();
      }
    } catch (e) {
      return _getDummyInteractions();
    }
  }

  Future<Interaction?> createInteraction(Map<String, dynamic> interactionData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/interactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(interactionData),
      );
      if (res.statusCode == 201) {
        return Interaction.fromMap(json.decode(res.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  List<Interaction> _getDummyInteractions() {
    return [
      Interaction(
        id: 'i1',
        doctorId: '6a156edec3f0acdfae0bb3de',
        doctorName: 'Dr. Arun Kumar',
        notes: 'Discussed clinical trial results for Cardivol 10mg. Doctor requested sample packs and brochures.',
        type: 'In-person',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Interaction(
        id: 'i2',
        doctorId: '6a156edec3f0acdfae0bb3df',
        doctorName: 'Dr. Sneha Reddy',
        notes: 'Followed up via phone call to discuss neurology department drug requirements for the next month.',
        type: 'Phone',
        date: DateTime.now(),
      ),
      Interaction(
        id: 'i3',
        doctorId: '6a156edec3f0acdfae0bb3e0',
        doctorName: 'Dr. Vikram Singh',
        notes: 'Conducted a virtual meeting presenting the orthopedic drug efficacy literature.',
        type: 'Virtual',
        date: DateTime.now().subtract(const Duration(days: 2)),
      ),
      Interaction(
        id: 'i4',
        doctorId: '6a156edec3f0acdfae0bb3e1',
        doctorName: 'Dr. Priya Sharma',
        notes: 'Sent pediatric drug dosage guide and clinical trial reports via email as requested.',
        type: 'Email',
        date: DateTime.now(),
      ),
      Interaction(
        id: 'i5',
        doctorId: '6a156edec3f0acdfae0bb3e2',
        doctorName: 'Dr. Rohan Mehta',
        notes: 'Met in-person to discuss correct brochure details for the Dermavit cream sample distribution.',
        type: 'In-person',
        date: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  Future<List<Doctor>> fetchDoctors() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/doctors'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        return data.map((e) => Doctor.fromMap(e)).toList();
      }
      return _getDummyDoctors();
    } catch (e) {
      return _getDummyDoctors();
    }
  }

  List<Doctor> _getDummyDoctors() {
    return [
      Doctor(
        id: '6a156edec3f0acdfae0bb3de',
        name: 'Dr. Arun Kumar',
        specialty: 'Cardiology',
        region: 'Hyderabad',
        mobile: '+919876543210',
        email: 'arun.kumar@health.com',
        status: 'Created',
        availableFrom: '09:00 AM',
        availableTo: '01:00 PM',
      ),
      Doctor(
        id: '6a156edec3f0acdfae0bb3df',
        name: 'Dr. Sneha Reddy',
        specialty: 'Neurology',
        region: 'Bangalore',
        mobile: '+919876543211',
        email: 'sneha.reddy@hospital.com',
        status: 'Created',
        availableFrom: '10:00 AM',
        availableTo: '04:00 PM',
      ),
      Doctor(
        id: '6a156edec3f0acdfae0bb3e0',
        name: 'Dr. Vikram Singh',
        specialty: 'Orthopedics',
        region: 'Chennai',
        mobile: '+919876543212',
        email: 'vikram.singh@clinic.com',
        status: 'Created',
        availableFrom: '02:00 PM',
        availableTo: '06:00 PM',
      ),
      Doctor(
        id: '6a156edec3f0acdfae0bb3e1',
        name: 'Dr. Priya Sharma',
        specialty: 'Pediatrics',
        region: 'Mumbai',
        mobile: '+919876543213',
        email: 'priya.sharma@medcare.com',
        status: 'Created',
        availableFrom: '09:00 AM',
        availableTo: '05:00 PM',
      ),
      Doctor(
        id: '6a156edec3f0acdfae0bb3e2',
        name: 'Dr. Rohan Mehta',
        specialty: 'Dermatology',
        region: 'Pune',
        mobile: '+919876543214',
        email: 'rohan.mehta@skinclinic.com',
        status: 'Created',
        availableFrom: '11:00 AM',
        availableTo: '03:00 PM',
      ),
    ];
  }

  Future<List<String>> fetchTechnicians() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/technicians'));
      if (res.statusCode == 200) {
        final List<dynamic> data = json.decode(res.body);
        final list = data.map<String>((e) => e['name'] as String).toList();
        if (list.isNotEmpty) return list;
      }
      return ['Tech Alex', 'Tech Sarah', 'Tech Rahul', 'Tech Mike'];
    } catch (e) {
      return ['Tech Alex', 'Tech Sarah', 'Tech Rahul', 'Tech Mike'];
    }
  }

  Future<void> createTechnician(String name, String email) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/technicians'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email}),
      );
    } catch (e) {
      // Offline fallback / log
    }
  }

  Future<Doctor?> createDoctor(Map<String, dynamic> doctorData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/doctors'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(doctorData),
      );
      if (res.statusCode == 201) {
        return Doctor.fromMap(json.decode(res.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

}
