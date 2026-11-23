import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  HapticService._();

  static Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('immersive_haptics_enabled') ?? true;
  }

  static Future<void> light() async {
    if (await isEnabled) await HapticFeedback.selectionClick();
  }

  static Future<void> success() async {
    if (await isEnabled) await HapticFeedback.mediumImpact();
  }

  static Future<void> warning() async {
    if (await isEnabled) {
      await HapticFeedback.heavyImpact();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> error() async {
    if (await isEnabled) {
      await HapticFeedback.vibrate();
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await HapticFeedback.vibrate();
    }
  }
}
