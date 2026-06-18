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
    return [];
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
    return [];
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
        id: '6a224fb319a418a64262ba60',
        name: 'Dr Chandramouli S',
        specialty: 'General Physician',
        region: 'Visakhapatnam',
        mobile: '8897208298',
        email: 'samathamcm@gmail.com',
        status: 'Saved',
        availableFrom: '9:00 AM',
        availableTo: '5:00 PM',
      ),
      Doctor(
        id: '6a2317f2582fb8e94a173ad6',
        name: 'Harshith',
        specialty: 'General Practice',
        region: 'Not Specified',
        mobile: '+353894938404',
        email: '',
        status: 'AI Agent Launched',
        availableFrom: '',
        availableTo: '',
      ),
      Doctor(
        id: '6a239b7699d2884d26be5438',
        name: 'Tota Deepa Swamy',
        specialty: 'General Practice',
        region: 'Not Specified',
        mobile: '9160011180',
        email: '',
        status: 'AI Agent Launched',
        availableFrom: '',
        availableTo: '',
      ),
      Doctor(
        id: '6a239c3b99d2884d26be5439',
        name: 'Dr Roopa',
        specialty: 'General Practice',
        region: 'Not Specified',
        mobile: '+919160011180',
        email: '',
        status: 'AI Agent Launched',
        availableFrom: '',
        availableTo: '',
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

  Future<Doctor?> updateDoctor(String id, Map<String, dynamic> doctorData) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/doctors/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(doctorData),
      );
      if (res.statusCode == 200) {
        return Doctor.fromMap(json.decode(res.body));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteDoctor(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/doctors/$id'));
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

}
