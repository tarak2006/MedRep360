import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/escalation.dart';
import '../models/interaction.dart';
import '../models/doctor.dart';

class SupabaseService {
	final SupabaseClient _client = Supabase.instance.client;

	Future<List<Escalation>> fetchEscalations() async {
		final res = await _client.from('escalations').select();
		if (res == null) return [];
		final list = List.from(res as List);
		return list.map((e) => Escalation.fromMap(Map<String, dynamic>.from(e))).toList();
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

