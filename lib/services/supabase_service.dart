import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/lead.dart';
import '../models/interaction.dart';
import '../models/doctor.dart';

class SupabaseService {
	final SupabaseClient _client = Supabase.instance.client;

	Future<List<Lead>> fetchLeads() async {
		try {
			final res = await _client.from('leads').select();
			final list = List.from(res);
			return list.map((e) => Lead.fromMap(Map<String, dynamic>.from(e))).toList();
		} catch (e) {
			// Fallback to dummy data if table is missing or query fails
			return _getDummyLeads();
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
			Lead(
				id: '3',
				doctorName: 'Dr. Charlie Brown',
				query: 'Need detailed literature on the new cardiovascular drug efficacy.',
				status: 'Pending',
				createdAt: DateTime.now().subtract(const Duration(hours: 4)),
			),
			Lead(
				id: '4',
				doctorName: 'Dr. Diana Prince',
				query: 'Delivery of last week\'s order is delayed by 3 days.',
				status: 'Resolved',
				assignedTo: 'Tech Sarah',
				createdAt: DateTime.now().subtract(const Duration(days: 5)),
			),
		];
	}

	Future<void> insertLead(Map<String, dynamic> payload) async {
		await _client.from('leads').insert(payload);
	}

	Future<void> updateLeadStatus(String id, String status) async {
		await _client.from('leads').update({'status': status}).eq('id', id);
	}

	Future<void> updateLeadTechnician(String id, String technician) async {
		await _client.from('leads').update({'assigned_to': technician, 'status': 'In Progress'}).eq('id', id);
	}

	Future<List<Interaction>> fetchInteractions() async {
		final res = await _client.from('interactions').select();
		final list = List.from(res);
		return list.map((e) => Interaction.fromMap(Map<String, dynamic>.from(e))).toList();
	}

	Future<List<Doctor>> fetchDoctors() async {
		final res = await _client.from('doctors').select();
		final list = List.from(res);
		return list.map((e) => Doctor.fromMap(Map<String, dynamic>.from(e))).toList();
	}
}

