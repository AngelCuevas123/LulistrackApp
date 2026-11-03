
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigation.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _isLoading = false;

  static const Color primaryNavy = Color(0xFF213A81);
  static const Color accentPink = Color(0xFFBA4078);
  static const Color subtitleBlue = Color(0xFF3B82F6);
  static const Color textGray = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // INICIAR SESION CON SUPABASE
  Future<void> _entrar() async {
    final email = _userController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo y contraseña.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Iniciar sesion en Supabase
      final authResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      // Obtener la sesion
      final session = authResponse.session;

      if (session == null) {
        throw Exception('No se pudo obtener la sesion.');
      }

      // GUARDAR TOKEN PARA LAS PETICIONES AL BACKEND
      ApiService.authToken = session.accessToken;

      print('Inicio de sesion correcto.');
      print('Token disponible: ${ApiService.authToken != null}');

      if (!mounted) return;

      // Entrar a la aplicacion
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const MainNavigationScreen(),
        ),
      );

    } on AuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: Colors.red,
        ),
      );

    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ocurrio un error: $error'),
          backgroundColor: Colors.red,
        ),
      );

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 20,
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ENCABEZADO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: primaryNavy,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 23,
                            ),
                          ),

                          const SizedBox(width: 10),

                          const Text(
                            'Lulistrack',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.bold,
                              color: primaryNavy,
                              letterSpacing: -0.7,
                            ),
                          ),
                        ],
                      ),

                      IconButton(
                        onPressed: () {},
                        icon: const Icon(
                          Icons.help_outline_rounded,
                          color: primaryNavy,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 25),

                  // IMAGEN PRINCIPAL
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),

                    child: SizedBox(
                      height: 205,
                      width: double.infinity,

                      child: Stack(
                        fit: StackFit.expand,
                        children: [

                          Image.network(
                            'https://images.pexels.com/photos/4393668/pexels-photo-4393668.jpeg',
                            fit: BoxFit.cover,

                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: primaryNavy,
                                child: const Icon(
                                  Icons.delivery_dining_rounded,
                                  size: 85,
                                  color: Colors.white,
                                ),
                              );
                            },
                          ),

                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  primaryNavy.withOpacity(0.85),
                                ],
                              ),
                            ),
                          ),

                          const Positioned(
                            left: 20,
                            right: 20,
                            bottom: 20,

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [

                                Text(
                                  'CADA ENTREGA CUENTA',
                                  style: TextStyle(
                                    color: Color(0xFFF5E17C),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.3,
                                  ),
                                ),

                                SizedBox(height: 6),

                                Text(
                                  'Tu ruta comienza aquí.',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(height: 3),

                                Text(
                                  'Conecta, entrega y sigue avanzando.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // TITULO DEL LOGIN
                  const Text(
                    'Bienvenido de nuevo',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      color: primaryNavy,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Inicia sesión para acceder a tu panel de repartidor.',
                    style: TextStyle(
                      fontSize: 14,
                      color: textGray,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  // CORREO
                  const Text(
                    'Correo electrónico',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryNavy,
                    ),
                  ),

                  const SizedBox(height: 9),

                  TextField(
                    controller: _userController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,

                    decoration: InputDecoration(
                      hintText: 'ejemplo@correo.com',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),

                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: textGray,
                        size: 21,
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 17,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: lightBorder,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CONTRASEÑA
                  const Text(
                    'Contraseña',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryNavy,
                    ),
                  ),

                  const SizedBox(height: 9),

                  TextField(
                    controller: _passwordController,
                    obscureText: _obscureText,
                    onSubmitted: (_) {
                      if (!_isLoading) _entrar();
                    },

                    decoration: InputDecoration(
                      hintText: 'Ingresa tu contraseña',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                      ),

                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: textGray,
                        size: 21,
                      ),

                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscureText = !_obscureText;
                          });
                        },

                        icon: Icon(
                          _obscureText
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: textGray,
                          size: 20,
                        ),
                      ),

                      filled: true,
                      fillColor: Colors.white,

                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 17,
                      ),

                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: lightBorder,
                        ),
                      ),

                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: primaryNavy,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // BOTON INICIAR SESION
                  SizedBox(
                    width: double.infinity,
                    height: 55,

                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _entrar,

                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentPink,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: accentPink.withOpacity(0.6),
                        elevation: 3,
                        shadowColor: accentPink.withOpacity(0.25),

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),

                      child: _isLoading
                          ? const SizedBox(
                              width: 23,
                              height: 23,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [

                                Text(
                                  'Iniciar sesión',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                SizedBox(width: 10),

                                Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // REGISTRO
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      children: [

                        const Text(
                          '¿Todavía no tienes una cuenta? ',
                          style: TextStyle(
                            color: textGray,
                            fontSize: 13,
                          ),
                        ),

                        GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'El registro estará disponible próximamente.',
                                ),
                              ),
                            );
                          },

                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: accentPink,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 27),

                  // SEGURIDAD
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        const Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF16A36A),
                          size: 17,
                        ),

                        const SizedBox(width: 7),

                        Text(
                          'Acceso seguro para repartidores',
                          style: TextStyle(
                            color: textGray.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Center(
                    child: Text(
                      'LULISTRACK PARA CONDUCTORES  ·  V 2.4',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
