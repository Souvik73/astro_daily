import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:astro_daily/app/astro_daily_app.dart';
import 'package:astro_daily/core/di/injection.dart';

void main() {
  testWidgets('login-first flow routes to home after sign in', (
    WidgetTester tester,
  ) async {
    await initDependencies(reset: true);
    await tester.pumpWidget(const AstroDailyApp());

    expect(find.text('Welcome to Astro Daily'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('login_email_field')),
      'pilot@astrodaily.app',
    );
    await tester.tap(find.byKey(const Key('login_continue_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome back'), findsOneWidget);
    expect(find.text('Astro Daily Modules'), findsOneWidget);
  });
}
