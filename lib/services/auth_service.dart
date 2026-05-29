import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
	final SupabaseClient _client = Supabase.instance.client;

	Future<AuthResponse> signInWithEmail(String email, String password) async {
		return await _client.auth.signInWithPassword(email: email, password: password);
	}

	Future<AuthResponse> signUpWithEmail(String email, String password, String name, String role) async {
		return await _client.auth.signUp(
			email: email,
			password: password,
			data: {
				'name': name,
				'role': role,
			},
		);
	}

	Future<void> signOut() async {
		await _client.auth.signOut();
	}

	Future<void> resetPassword(String email) async {
		await _client.auth.resetPasswordForEmail(email);
	}
}
