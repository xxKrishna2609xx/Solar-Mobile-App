import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:solar_pro/main.dart';

void main() {
  testWidgets('SolarProApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SolarProApp()));
    expect(find.byType(SolarProApp), findsOneWidget);
  });
}
