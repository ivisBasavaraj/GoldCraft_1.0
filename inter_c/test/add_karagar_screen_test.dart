import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inter_c/features/karagars/presentation/screens/add_karagar_screen.dart';

void main() {
  testWidgets('requires a profile picture to register a Karagar',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: AddKaragarScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Raju Kumar');
    await tester.enterText(find.byType(TextFormField).at(1), 'GC-005');
    await tester.enterText(find.byType(TextFormField).at(3), 'Bangles');
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Register Karagar'));
    await tester.tap(find.text('Register Karagar'));
    await tester.pump();

    expect(find.text('A profile picture is required'), findsOneWidget);
  });
}
