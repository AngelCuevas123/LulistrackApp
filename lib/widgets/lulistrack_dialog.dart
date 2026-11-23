import 'package:flutter/material.dart';

/// Dialogos consistentes para confirmar acciones y comunicar estados al repartidor.
class LulistrackDialog {
  static const Color _navy = Color(0xFF1E3A8A);
  static const Color _pink = Color(0xFFC23B75);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE2E8F0);

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Continuar',
    String cancelLabel = 'Cancelar',
    IconData icon = Icons.help_outline_rounded,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(icon, color: _pink, size: 34),
        title: Text(title, textAlign: TextAlign.center,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
        content: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              style: OutlinedButton.styleFrom(
                foregroundColor: _navy,
                side: const BorderSide(color: _border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(cancelLabel),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: _pink,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(confirmLabel),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<void> warning(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Entendido',
  }) => _message(context, title, message, Icons.warning_amber_rounded,
      const Color(0xFFD97706), buttonLabel);

  static Future<void> error(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Reintentar',
  }) => _message(context, title, message, Icons.error_outline_rounded,
      const Color(0xFFDC2626), buttonLabel);

  static Future<void> success(
    BuildContext context, {
    required String title,
    required String message,
    String buttonLabel = 'Continuar',
  }) => _message(context, title, message, Icons.check_circle_outline_rounded,
      const Color(0xFF16A34A), buttonLabel);

  static Future<void> _message(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color color,
    String buttonLabel,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        icon: Icon(icon, color: color, size: 36),
        title: Text(title, textAlign: TextAlign.center,
          style: const TextStyle(color: _navy, fontWeight: FontWeight.w800)),
        content: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: _muted, height: 1.45)),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              style: FilledButton.styleFrom(
                backgroundColor: _navy,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
