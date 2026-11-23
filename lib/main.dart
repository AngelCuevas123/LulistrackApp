import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/session_gate_screen.dart';
import 'services/api_service.dart';
import 'screens/lulistrack_splash_screen.dart';
import 'package:flutter/cupertino.dart';
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Mensaje recibido: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: '.env');
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
  final apiBaseUrl = dotenv.env['API_BASE_URL'];

  if (supabaseUrl == null || supabaseUrl.isEmpty ||
      supabaseAnonKey == null || supabaseAnonKey.isEmpty ||
      apiBaseUrl == null || apiBaseUrl.isEmpty) {
    throw StateError('Faltan variables de configuracion en el archivo .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  // Mantener actualizado el token que utiliza ApiService cuando Supabase
  // renueva la sesión automáticamente.
  Supabase.instance.client.auth.onAuthStateChange.listen((authState) {
    ApiService.authToken = authState.session?.accessToken;
    if (authState.session == null) {
      ApiService.currentDriver = null;
    }
  });

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
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const LulistrackSplashScreen(nextScreen: SessionGateScreen()),
    );
  }
}
