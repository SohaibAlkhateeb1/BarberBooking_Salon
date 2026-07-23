import 'package:flutter_test/flutter_test.dart';
import 'package:barber_booking/main.dart';
import 'package:barber_booking/core/theme/theme_controller.dart';

void main() {
  testWidgets('App starts', (WidgetTester tester) async {
    final themeController = ThemeController();
    await tester.pumpWidget(BarberBookingApp(themeController: themeController));
    expect(find.byType(BarberBookingApp), findsOneWidget);
  });
}
