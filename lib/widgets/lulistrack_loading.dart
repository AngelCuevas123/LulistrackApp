import 'package:flutter/material.dart';

class LulistrackLoading extends StatelessWidget {
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
  Widget build(BuildContext context) {
    const navy = Color(0xFF213A81);
    const pink = Color(0xFFBA4078);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: .82, end: 1),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeInOut,
              builder: (_, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: navy, size: 34),
              ),
            ),
            const SizedBox(height: 22),
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.all(Radius.circular(8)),
                color: pink,
                backgroundColor: Color(0xFFE9EAF2),
              ),
            ),
            const SizedBox(height: 18),
            Text(title, textAlign: TextAlign.center,
                style: const TextStyle(
                  color: navy, fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF64748B), fontSize: 12, height: 1.4)),
          ],
        ),
      ),
    );
  }
}
