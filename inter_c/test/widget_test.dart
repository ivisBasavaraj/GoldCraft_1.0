import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inter_c/main.dart';

void main() {
  testWidgets('App launches without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: GoldCraftApp()));
    await tester.pump();
    expect(find.byType(GoldCraftApp), findsOneWidget);
  });
}
