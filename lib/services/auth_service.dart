import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
	final SupabaseClient _client = Supabase.instance.client;

	Future<AuthResponse> signInWithEmail(String email, String password) async {
		return await _client.auth.signInWithPassword(email: email, password: password);
	}

	Future<AuthResponse> signUpWithEmail(String email, String password) async {
		return await _client.auth.signUp(email: email, password: password);
	}

	Future<void> signOut() async {
		await _client.auth.signOut();
	}

	Future<void> resetPassword(String email) async {
		await _client.auth.resetPasswordForEmail(email);
	}
}
