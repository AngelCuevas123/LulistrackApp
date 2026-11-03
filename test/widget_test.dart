import 'package:flutter_test/flutter_test.dart';
import 'package:lulistrack_app/main.dart';

void main() {
  testWidgets('Muestra la pantalla de inicio de sesion de Lulistrack',
      (WidgetTester tester) async {
    await tester.pumpWidget(const LulistrackApp());

    expect(find.text('Bienvenido de nuevo'), findsOneWidget);
    expect(
      find.text('Inicia sesión para acceder a tu panel de repartidor.'),
      findsOneWidget,
    );
    expect(find.text('Correo electrónico'), findsOneWidget);
  });
}
