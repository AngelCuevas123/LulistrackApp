
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'main_navigation.dart';
import 'forgot_password_screen.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
import '../widgets/lulistrack_loading.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  bool _obscureText = true;
  bool _isLoading = false;
  bool _isNavigating = false;

  static const Color primaryNavy = Color(0xFF213A81);
  static const Color accentPink = Color(0xFFBA4078);
  static const Color subtitleBlue = Color(0xFF3B82F6);
  static const Color textGray = Color(0xFF6B7280);
  static const Color lightBorder = Color(0xFFE5E7EB);
  static const Color background = Color(0xFFF8FAFC);

  static const String loginImage =
      'assets/images/lulistrack_login.jpg';

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ============================================================
  // ACCESO BIOMETRICO
  // ============================================================

  Future<void> _offerBiometricsAfterLogin() async {
    final biometric = BiometricService.instance;

    if (await biometric.wasPrompted()) return;

    await biometric.markPrompted();

    if (!await biometric.isAvailable() || !mounted) return;

    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        icon: const Icon(
          Icons.fingerprint_rounded,
          color: primaryNavy,
          size: 46,
        ),
        title: const Text(
          'Activa el acceso biométrico',
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'La próxima vez podrás desbloquear Lulistrack '
              'con la huella o el reconocimiento facial de este dispositivo. '
              'Tu contraseña no se guardará.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: accentPink,
            ),
            child: const Text('Activar'),
          ),
        ],
      ),
    );

    if (enable != true || !mounted) return;

    final authenticated = await biometric.authenticate(
      reason: 'Confirma tu identidad para activar el acceso biométrico.',
    );

    if (authenticated) {
      await biometric.setEnabled(true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Acceso biométrico activado correctamente.'),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo activar la biometría. '
                'Puedes intentarlo desde Seguridad y Privacidad.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // INICIO DE SESION
  // ============================================================

  Future<void> _entrar() async {
    if (_isLoading || _isNavigating) return;

    FocusScope.of(context).unfocus();

    final email = _userController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Ingresa tu correo y contraseña.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse =
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = authResponse.session;

      if (session == null) {
        throw Exception('No se pudo obtener la sesión.');
      }

      ApiService.authToken = session.accessToken;
      ApiService.currentDriver = null;

      await ApiService.getMyDriverProfile(forceRefresh: true);

      await _offerBiometricsAfterLogin();

      debugPrint('Inicio de sesión correcto.');
      debugPrint(
        'Token disponible: ${ApiService.authToken != null}',
      );

      if (!mounted) return;

      _isNavigating = true;

      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const MainNavigationScreen(),
        ),
            (route) => false,
      );

      // Las notificaciones no bloquean el acceso.
      unawaited(
        NotificationService.initializeAndRegister().catchError(
              (Object error) {
            debugPrint('No se pudo registrar FCM: $error');
          },
        ),
      );
    } on AuthException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.message,
        isError: true,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        'Ocurrió un error: $error',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MENSAJES
  // ============================================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : primaryNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
  }

  // ============================================================
  // RECUPERACION DE CONTRASEÑA
  // ============================================================

  void _openForgotPassword() {
    if (_isLoading) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          initialEmail: _userController.text.trim(),
        ),
      ),
    );
  }

  // ============================================================
  // ENCABEZADO
  // ============================================================

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: primaryNavy,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: primaryNavy.withOpacity(0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lulistrack',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: primaryNavy,
                  letterSpacing: -0.8,
                ),
              ),
              Text(
                'DELIVERY MANAGEMENT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: textGray,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: lightBorder),
          ),
          child: IconButton(
            onPressed: () {
              _showMessage(
                'Para solicitar asistencia, contacta al administrador '
                    'de Lulistrack.',
              );
            },
            icon: const Icon(
              Icons.help_outline_rounded,
              color: primaryNavy,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // IMAGEN PRINCIPAL
  // ============================================================

  Widget _buildHeroImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: SizedBox(
        height: 220,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              loginImage,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                debugPrint('Error cargando imagen: $error');

                return Container(
                  color: primaryNavy,
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: Colors.white,
                    size: 85,
                  ),
                );
              },
            ),

            // Degradado para mejorar la lectura del texto.
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryNavy.withOpacity(0.03),
                    primaryNavy.withOpacity(0.18),
                    primaryNavy.withOpacity(0.88),
                  ],
                ),
              ),
            ),

            // Etiqueta superior.
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: accentPink,
                      size: 15,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'LOGÍSTICA INTELIGENTE',
                      style: TextStyle(
                        color: primaryNavy,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Mensaje principal.
            const Positioned(
              left: 21,
              right: 21,
              bottom: 21,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CADA ENTREGA CUENTA',
                    style: TextStyle(
                      color: Color(0xFFF5E17C),
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  SizedBox(height: 7),
                  Text(
                    'Tu ruta comienza aquí.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Conecta, entrega y sigue avanzando.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CAMPOS DE TEXTO
  // ============================================================

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: primaryNavy,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: textGray,
        size: 21,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: lightBorder,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: primaryNavy,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Correo electrónico'),
        const SizedBox(height: 9),
        TextField(
          controller: _userController,
          focusNode: _emailFocus,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
          onSubmitted: (_) {
            _passwordFocus.requestFocus();
          },
          decoration: _inputDecoration(
            hint: 'ejemplo@correo.com',
            icon: Icons.email_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel('Contraseña'),
        const SizedBox(height: 9),
        TextField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          obscureText: _obscureText,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) _entrar();
          },
          decoration: _inputDecoration(
            hint: 'Ingresa tu contraseña',
            icon: Icons.lock_outline_rounded,
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
          ),
        ),
      ],
    );
  }

  // ============================================================
  // BOTON PRINCIPAL
  // ============================================================

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _entrar,
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: accentPink.withOpacity(0.6),
          elevation: 3,
          shadowColor: accentPink.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const LulistrackActionLoading(
          color: Colors.white,
          size: 22,
        )
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_rounded,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SOLICITUD DE ACCESO
  // ============================================================

  Widget _buildRegistration() {
    return Center(
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
              _showMessage(
                'Solicita tu acceso al administrador '
                    'desde el Dashboard de Lulistrack.',
              );
            },
            child: const Text(
              'Solicitar acceso',
              style: TextStyle(
                color: accentPink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SEGURIDAD Y VERSION
  // ============================================================

  Widget _buildSecurityFooter() {
    return Column(
      children: [
        Row(
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
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        const Text(
          'LULISTRACK PARA CONDUCTORES  ·  V 2.4',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF9CA3AF),
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INTERFAZ PRINCIPAL
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 22,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 480,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),

                      const SizedBox(height: 25),

                      _buildHeroImage(),

                      const SizedBox(height: 31),

                      const Text(
                        'Bienvenido de nuevo',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: primaryNavy,
                          letterSpacing: -0.9,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Inicia sesión para acceder a tu panel '
                            'de repartidor.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textGray,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 27),

                      _buildEmailField(),

                      const SizedBox(height: 20),

                      _buildPasswordField(),

                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed:
                          _isLoading ? null : _openForgotPassword,
                          style: TextButton.styleFrom(
                            foregroundColor: accentPink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 5,
                            ),
                            minimumSize: const Size(48, 40),
                          ),
                          child: const Text(
                            '¿Olvidaste tu contraseña?',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      _buildLoginButton(),

                      const SizedBox(height: 25),

                      _buildRegistration(),

                      const SizedBox(height: 29),

                      _buildSecurityFooter(),

                      const SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
