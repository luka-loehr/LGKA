import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lgka_flutter/widgets/app_footer.dart';

void main() {
  testWidgets('renders author and version metadata', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppFooter(),
        ),
      ),
    );

    expect(find.text('Luka Löhr'), findsOneWidget);
    expect(find.textContaining('vunknown'), findsOneWidget);
  });
}
