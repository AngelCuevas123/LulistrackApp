import 'dart:math' as math;

import 'package:flutter/material.dart';

class LulistrackSplashScreen extends StatefulWidget {
  final Widget nextScreen;

  const LulistrackSplashScreen({
    super.key,
    required this.nextScreen,
  });

  @override
  State<LulistrackSplashScreen> createState() => _LulistrackSplashScreenState();
}

class _LulistrackSplashScreenState extends State<LulistrackSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..forward();

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 5550), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 850),
          pageBuilder: (_, animation, __) => FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: widget.nextScreen,
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  double _phase(double begin, double end, {Curve curve = Curves.easeOutCubic}) {
    return curve.transform(
      ((_intro.value - begin) / (end - begin)).clamp(0.0, 1.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF101D43);
    const blue = Color(0xFF213A81);
    const cyan = Color(0xFFB7E7FC);
    const pink = Color(0xFFBA4078);
    const yellow = Color(0xFFF5E17C);

    return Scaffold(
      backgroundColor: navy,
      body: AnimatedBuilder(
        animation: Listenable.merge([_intro, _ambient]),
        builder: (context, _) {
          final mapOpacity = _phase(0.0, 0.25);
          final routeProgress = _phase(0.12, 0.69, curve: Curves.easeInOutCubic);
          final logoProgress = _phase(0.57, 0.86, curve: Curves.easeOutBack);
          final taglineProgress = _phase(0.78, 0.96);
          final finishProgress = _phase(0.88, 1.0);
          final float = math.sin(_ambient.value * math.pi) * 5;

          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF101D43), Color(0xFF213A81), Color(0xFF142650)],
                    stops: [0, 0.56, 1],
                  ),
                ),
              ),
              Opacity(
                opacity: mapOpacity,
                child: CustomPaint(
                  painter: _LulistrackMapPainter(routeProgress),
                ),
              ),
              Positioned(
                top: -110,
                right: -95,
                child: Opacity(
                  opacity: 0.14,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [cyan, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                top: MediaQuery.paddingOf(context).top + 28,
                child: Opacity(
                  opacity: mapOpacity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(11),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: const Icon(
                              Icons.hub_rounded,
                              color: cyan,
                              size: 19,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'DELIVERY NETWORK',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              letterSpacing: 2.0,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.13)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.circle, color: Color(0xFF75E0B2), size: 7),
                            SizedBox(width: 6),
                            Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 30 + (MediaQuery.sizeOf(context).width - 90) * routeProgress,
                top: MediaQuery.sizeOf(context).height * (0.67 - 0.31 * routeProgress) + float,
                child: Opacity(
                  opacity: _phase(0.12, 0.26) * (1 - _phase(0.58, 0.72) * 0.35),
                  child: Transform.rotate(
                    angle: -0.20,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: pink,
                        borderRadius: BorderRadius.circular(19),
                        boxShadow: [
                          BoxShadow(
                            color: pink.withValues(alpha: 0.42),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                      ),
                      child: const Icon(
                        Icons.delivery_dining_rounded,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - logoProgress)),
                  child: Opacity(
                    opacity: logoProgress.clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.72 + (0.28 * logoProgress),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 118,
                            height: 118,
                            padding: const EdgeInsets.all(17),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(34),
                              boxShadow: [
                                BoxShadow(
                                  color: cyan.withValues(alpha: 0.20),
                                  blurRadius: 48,
                                  spreadRadius: 2,
                                ),
                                const BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 30,
                                  offset: Offset(0, 16),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/icon/lulistrack_icon.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 25),
                          const Text(
                            'LULISTRACK',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 3.4,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Opacity(
                            opacity: taglineProgress,
                            child: const Text(
                              'CADA ENTREGA CUENTA',
                              style: TextStyle(
                                color: yellow,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 3.1,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Opacity(
                            opacity: taglineProgress,
                            child: Container(
                              width: 44 + (48 * _ambient.value),
                              height: 3,
                              decoration: BoxDecoration(
                                color: cyan.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 28,
                right: 28,
                bottom: MediaQuery.paddingOf(context).bottom + 42,
                child: Opacity(
                  opacity: (1 - logoProgress * 0.65).clamp(0.0, 1.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.route_rounded,
                            color: cyan.withValues(alpha: 0.9),
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'CONECTANDO CADA DESTINO',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: routeProgress,
                          minHeight: 2.5,
                          backgroundColor: Colors.white.withValues(alpha: 0.13),
                          valueColor: const AlwaysStoppedAnimation(yellow),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: finishProgress * 0.16,
                    child: Container(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LulistrackMapPainter extends CustomPainter {
  final double progress;

  const _LulistrackMapPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.075)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final roadCenterPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final roads = <Path>[
      Path()
        ..moveTo(-20, size.height * 0.25)
        ..cubicTo(size.width * 0.28, size.height * 0.18, size.width * 0.50, size.height * 0.34, size.width + 20, size.height * 0.22),
      Path()
        ..moveTo(-30, size.height * 0.52)
        ..cubicTo(size.width * 0.30, size.height * 0.43, size.width * 0.62, size.height * 0.63, size.width + 30, size.height * 0.48),
      Path()
        ..moveTo(size.width * 0.18, -20)
        ..cubicTo(size.width * 0.28, size.height * 0.30, size.width * 0.08, size.height * 0.68, size.width * 0.34, size.height + 20),
      Path()
        ..moveTo(size.width * 0.76, -20)
        ..cubicTo(size.width * 0.62, size.height * 0.28, size.width * 0.92, size.height * 0.62, size.width * 0.72, size.height + 20),
    ];

    for (final road in roads) {
      canvas.drawPath(road, roadPaint);
      canvas.drawPath(road, roadCenterPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.10, size.height * 0.72)
      ..cubicTo(size.width * 0.25, size.height * 0.62, size.width * 0.27, size.height * 0.88, size.width * 0.43, size.height * 0.76)
      ..cubicTo(size.width * 0.59, size.height * 0.64, size.width * 0.48, size.height * 0.47, size.width * 0.67, size.height * 0.43)
      ..cubicTo(size.width * 0.82, size.height * 0.40, size.width * 0.72, size.height * 0.23, size.width * 0.90, size.height * 0.19);

    final metric = route.computeMetrics().first;
    final visibleRoute = metric.extractPath(0, metric.length * progress);
    final glowPaint = Paint()
      ..color = const Color(0xFFB7E7FC).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 13
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9);
    final routePaint = Paint()
      ..color = const Color(0xFFF5E17C)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(visibleRoute, glowPaint);
    canvas.drawPath(visibleRoute, routePaint);

    final start = Offset(size.width * 0.10, size.height * 0.72);
    final end = Offset(size.width * 0.90, size.height * 0.19);
    for (final point in [start, end]) {
      canvas.drawCircle(
        point,
        10,
        Paint()..color = const Color(0xFFB7E7FC).withValues(alpha: 0.16),
      );
      canvas.drawCircle(
        point,
        4,
        Paint()..color = const Color(0xFFB7E7FC),
      );
    }

    final destination = metric.getTangentForOffset(metric.length * progress);
    if (destination != null) {
      canvas.drawCircle(
        destination.position,
        12,
        Paint()..color = const Color(0xFFF5E17C).withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        destination.position,
        4,
        Paint()..color = const Color(0xFFF5E17C),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LulistrackMapPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
