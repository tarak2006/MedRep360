import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation.dart';
import '../models/interaction.dart';
import '../models/doctor.dart';

class SupabaseService {
	final SupabaseClient _client = Supabase.instance.client;

	Future<List<Escalation>> fetchEscalations() async {
		try {
			final res = await _client.from('escalations').select();
			if (res == null) return _getDummyEscalations();
			final list = List.from(res as List);
			return list.map((e) => Escalation.fromMap(Map<String, dynamic>.from(e))).toList();
		} catch (e) {
			// Fallback to dummy data if table is missing or query fails
			return _getDummyEscalations();
		}
	}

	List<Escalation> _getDummyEscalations() {
		return [
			Escalation(
				id: 1,
				doctorName: 'Dr. Alice Smith',
				query: 'Requested samples of Paracetamol 500mg but only received 250mg.',
				status: 'Pending',
				createdAt: DateTime.now().subtract(const Duration(days: 2)),
			),
			Escalation(
				id: 2,
				doctorName: 'Dr. Bob Jones',
				query: 'The login credentials for the portal are not working.',
				status: 'In Progress',
				assignedTo: 'Tech Alex',
				createdAt: DateTime.now().subtract(const Duration(days: 1)),
			),
			Escalation(
				id: 3,
				doctorName: 'Dr. Charlie Brown',
				query: 'Need detailed literature on the new cardiovascular drug efficacy.',
				status: 'Pending',
				createdAt: DateTime.now().subtract(const Duration(hours: 4)),
			),
			Escalation(
				id: 4,
				doctorName: 'Dr. Diana Prince',
				query: 'Delivery of last week\'s order is delayed by 3 days.',
				status: 'Resolved',
				assignedTo: 'Tech Sarah',
				createdAt: DateTime.now().subtract(const Duration(days: 5)),
			),
		];
	}

	Future<void> insertEscalation(Map<String, dynamic> payload) async {
		await _client.from('escalations').insert(payload);
	}

	Future<void> updateEscalationStatus(int id, String status) async {
		await _client.from('escalations').update({'status': status}).eq('id', id);
	}

	Future<void> updateEscalationTechnician(int id, String technician) async {
		await _client.from('escalations').update({'assigned_to': technician, 'status': 'In Progress'}).eq('id', id);
	}

	Future<List<Interaction>> fetchInteractions() async {
		final res = await _client.from('interactions').select();
		if (res == null) return [];
		final list = List.from(res as List);
		return list.map((e) => Interaction.fromMap(Map<String, dynamic>.from(e))).toList();
	}

	Future<List<Doctor>> fetchDoctors() async {
		final res = await _client.from('doctors').select();
		if (res == null) return [];
		final list = List.from(res as List);
		return list.map((e) => Doctor.fromMap(Map<String, dynamic>.from(e))).toList();
	}
}

