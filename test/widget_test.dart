import 'package:astro_daily/features/ui_preview/presentation/ui_preview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ui preview renders the redesigned core screens', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1720, 2400);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: UiPreviewPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Astro Daily UI Direction'), findsOneWidget);
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(find.text('DAILY HOROSCOPE'), findsOneWidget);
    expect(find.text('SUBSCRIPTION'), findsOneWidget);
    expect(find.text('Premium, softened'), findsOneWidget);
  });
}
