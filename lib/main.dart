import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/interactions/interactions_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://ooyoaprsluvvegfwuytd.supabase.co',
    anonKey: 'sb_publishable_3uZy3q1Nxmfsjji3qb72mQ_06dfYrvt', // your key
  );

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