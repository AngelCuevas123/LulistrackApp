import 'dart:math' as math;

import 'package:flutter/material.dart';

class LulistrackLoading extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const LulistrackLoading({
    super.key,
    this.title = 'Preparando todo',
    this.subtitle = 'Un momento, estamos trabajando en ello.',
    this.icon = Icons.route_rounded,
  });

  @override
  State<LulistrackLoading> createState() => _LulistrackLoadingState();
}

class _LulistrackLoadingState extends State<LulistrackLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2300),
  )..repeat();

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF213A81);
    const pink = Color(0xFFBA4078);
    const cyan = Color(0xFFB7E7FC);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 24),
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) {
            final wave = math.sin(_motion.value * math.pi * 2);
            final progress = (_motion.value * 0.72 + 0.16).clamp(0.0, 1.0);

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 154,
                  height: 142,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.92 + (0.08 * wave.abs()),
                        child: Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: navy.withValues(alpha: 0.07),
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: 92,
                        height: 92,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEEF2FF),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withValues(alpha: 0.65),
                              blurRadius: 24 + (wave.abs() * 10),
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -5 + (wave * 4)),
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            boxShadow: [
                              BoxShadow(
                                color: navy.withValues(alpha: 0.10),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(widget.icon, color: navy, size: 34),
                        ),
                      ),
                      Transform.rotate(
                        angle: _motion.value * math.pi * 2,
                        child: SizedBox(
                          width: 132,
                          height: 132,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                color: pink,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: pink.withValues(alpha: 0.35),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 7,
                        bottom: 15,
                        child: Transform.translate(
                          offset: Offset(0, wave * 3),
                          child: Container(
                            width: 29,
                            height: 29,
                            decoration: BoxDecoration(
                              color: pink,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: pink.withValues(alpha: 0.24),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 17),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hub_rounded, color: navy, size: 12),
                      SizedBox(width: 6),
                      Text(
                        'LULISTRACK  •  EN PROCESO',
                        style: TextStyle(
                          color: navy,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: navy,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 7),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 270),
                  child: Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: 174,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      children: [
                        Container(height: 4, color: const Color(0xFFE8ECF5)),
                        FractionallySizedBox(
                          widthFactor: progress,
                          child: Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [navy, cyan, pink],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _loadingCaption(_motion.value),
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _loadingCaption(double value) {
    if (value < 0.33) return 'Conectando con tu operación';
    if (value < 0.66) return 'Organizando la información';
    return 'Un paso más y estará listo';
  }
}

/// Indicador compacto para acciones dentro de botones.
class LulistrackActionLoading extends StatefulWidget {
  final Color color;
  final double size;

  const LulistrackActionLoading({
    super.key,
    this.color = Colors.white,
    this.size = 19,
  });

  @override
  State<LulistrackActionLoading> createState() => _LulistrackActionLoadingState();
}

class _LulistrackActionLoadingState extends State<LulistrackActionLoading>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: _controller.value * math.pi * 2,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    width: widget.size * 0.28,
                    height: widget.size * 0.28,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Icon(Icons.local_shipping_rounded, color: widget.color, size: widget.size * 0.72),
            ],
          ),
        );
      },
    );
  }
}
