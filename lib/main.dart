import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/interactions/interactions_page.dart';

import 'services/storage_check.dart';

class InMemoryLocalStorage extends LocalStorage {
  final Map<String, String> _storage = {};

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return _storage.containsKey('SUPABASE_PERSIST_SESSION_KEY');
  }

  @override
  Future<String?> accessToken() async {
    return _storage['SUPABASE_PERSIST_SESSION_KEY'];
  }

  @override
  Future<void> removePersistedSession() async {
    _storage.remove('SUPABASE_PERSIST_SESSION_KEY');
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    _storage['SUPABASE_PERSIST_SESSION_KEY'] = persistSessionString;
  }
}

class InMemoryGotrueAsyncStorage extends GotrueAsyncStorage {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getItem({required String key}) async {
    return _storage[key];
  }

  @override
  Future<void> removeItem({required String key}) async {
    _storage.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) async {
    _storage[key] = value;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool storageAvailable = checkStorage();

  if (storageAvailable) {
    await Supabase.initialize(
      url: 'https://ooyoaprsluvvegfwuytd.supabase.co',
      anonKey: 'sb_publishable_3uZy3q1Nxmfsjji3qb72mQ_06dfYrvt', // your key
    );
  } else {
    // If local storage is blocked (e.g. Incognito mode or third-party iframe domain),
    // use in-memory storage to prevent crash.
    await Supabase.initialize(
      url: 'https://ooyoaprsluvvegfwuytd.supabase.co',
      anonKey: 'sb_publishable_3uZy3q1Nxmfsjji3qb72mQ_06dfYrvt', // your key
      authOptions: FlutterAuthClientOptions(
        localStorage: InMemoryLocalStorage(),
        pkceAsyncStorage: InMemoryGotrueAsyncStorage(),
      ),
    );
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedRep 360',
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/interactions': (context) => const InteractionsPage(),
      },
    );
  }
}