
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
  url: 'https://dzlvdtfzobeaayiutjik.supabase.co',
  anonKey: 'sb_publishable_AN7MAoEMoSH-jY5u8CCY4w_nZXn9daN',
);

  runApp(const LulistrackApp());
}

class LulistrackApp extends StatelessWidget {
  const LulistrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lulistrack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: const LoginScreen(),
    );
  }
}
