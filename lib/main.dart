
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';

// Manejo de notificaciones cuando la aplicación está en segundo plano.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(
    RemoteMessage message,
    ) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  debugPrint('Mensaje recibido: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Registrar el manejador de mensajes en segundo plano.
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );

  // Cargar variables de entorno.
  await dotenv.load(fileName: '.env');

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  final apiBaseUrl = dotenv.env['API_BASE_URL'];

  if (supabaseUrl == null ||
      supabaseUrl.isEmpty ||
      supabaseAnonKey == null ||
      supabaseAnonKey.isEmpty ||
      apiBaseUrl == null ||
      apiBaseUrl.isEmpty) {
    throw StateError(
      'Faltan variables de configuracion en el archivo .env',
    );
  }

  // Inicializar Supabase.
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
