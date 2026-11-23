import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LulistrackSplashScreen extends StatefulWidget {
  final Widget nextScreen;
  const LulistrackSplashScreen({super.key, required this.nextScreen});

  @override
  State<LulistrackSplashScreen> createState() => _LulistrackSplashScreenState();
}

class _LulistrackSplashScreenState extends State<LulistrackSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _route = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..forward();
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3600), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 650),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: animation,
            child: widget.nextScreen,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _route.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF213A81);
    const pink = Color(0xFFBA4078);
    return Scaffold(
      backgroundColor: navy,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: _MapPainter(_route)),
          Positioned(
            top: 90,
            right: 28,
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, child) => Transform.scale(
                scale: 0.92 + (_pulse.value * 0.12),
                child: child,
              ),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.10),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.gps_fixed_rounded,
                    color: Color(0xFFF5E17C), size: 22),
              ),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _route,
              builder: (_, __) {
                final t = Curves.easeOutBack.transform(
                  ((_route.value - .48) / .52).clamp(0.0, 1.0),
                );
                return Opacity(
                  opacity: t.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: .72 + (.28 * t),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(.22),
                                blurRadius: 35,
                                offset: const Offset(0, 14),
                              )
                            ],
                          ),
                          padding: const EdgeInsets.all(18),
                          child: Image.asset('assets/icon/lulistrack_icon.png'),
                        ),
                        const SizedBox(height: 22),
                        const Text('Lulistrack',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -.8,
                            )),
                        const SizedBox(height: 7),
                        const Text('CADA ENTREGA CUENTA',
                            style: TextStyle(
                              color: Color(0xFFF5E17C),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2.4,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          AnimatedBuilder(
            animation: _route,
            builder: (_, __) {
              final t = _route.value.clamp(0.0, 1.0);
              return Positioned(
                left: MediaQuery.sizeOf(context).width * (.12 + .68 * t),
                top: MediaQuery.sizeOf(context).height * (.72 - .34 * t),
                child: Transform.rotate(
                  angle: -.48,
                  child: Container(
                    padding: const EdgeInsets.all(11),
                    decoration: BoxDecoration(
                      color: pink,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 18)
                      ],
                    ),
                    child: const Icon(Icons.delivery_dining_rounded,
                        color: Colors.white, size: 30),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0, right: 0, bottom: 54,
            child: Column(
              children: [
                SizedBox(
                  width: 110,
                  child: AnimatedBuilder(
                    animation: _route,
                    builder: (_, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        value: _route.value,
                        minHeight: 3,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Color(0xFFF5E17C)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Preparando tu ruta...',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final Animation<double> animation;
  _MapPainter(this.animation) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withOpacity(.055)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width; x += 42) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), grid);
    }
    for (double y = 35; y < size.height; y += 72) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 18), grid);
    }

    final route = Path()
      ..moveTo(size.width * .10, size.height * .74)
      ..cubicTo(size.width * .28, size.height * .64,
          size.width * .28, size.height * .92,
          size.width * .48, size.height * .78)
      ..cubicTo(size.width * .65, size.height * .66,
          size.width * .56, size.height * .46,
          size.width * .82, size.height * .30);
    final metric = route.computeMetrics().first;
    final part = metric.extractPath(0, metric.length * animation.value);
    final line = Paint()
      ..color = const Color(0xFFF5E17C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(part, line);

    final glow = Paint()
      ..color = const Color(0xFFF5E17C).withOpacity(.13)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(size.width * .82, size.height * .30), 20, glow);
    canvas.drawCircle(Offset(size.width * .82, size.height * .30), 6,
        Paint()..color = const Color(0xFFF5E17C));
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => false;
}
