import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/login_screen.dart';

Future<void> main() async {
  // Primero preparo Flutter para poder cargar la configuracion antes de iniciar la app.
  WidgetsFlutterBinding.ensureInitialized();

  // Leo las direcciones y claves publicas desde .env para no dejarlas escritas en el codigo.
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  final apiBaseUrl = dotenv.env['API_BASE_URL'];

  // Compruebo que la configuracion necesaria exista antes de conectar los servicios.
  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty ||
      apiBaseUrl == null ||
      apiBaseUrl.isEmpty) {
    throw StateError('Faltan variables de configuracion en el archivo .env');
  }

  // Inicializo Supabase con la clave publica que utiliza la aplicacion movil.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  // Cuando los servicios estan listos, muestro la aplicacion.
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
