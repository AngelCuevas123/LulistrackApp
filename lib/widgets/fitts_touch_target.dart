/// Criterios táctiles basados en la Ley de Fitts para Lulistrack.
///
/// Se adopta 48 logical px como mínimo para controles táctiles y 56 logical px
/// para acciones principales frecuentes. Son objetivos de diseño, no una
/// medición experimental del tiempo de interacción.
class FittsTouchTarget {
  FittsTouchTarget._();

  static const double minimum = 48;
  static const double primary = 56;
  static const double icon = 48;
}
