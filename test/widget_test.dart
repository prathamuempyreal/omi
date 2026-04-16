import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:omi/core/theme/app_theme.dart';
import 'package:omi/core/widgets/glass_card.dart';

void main() {
  testWidgets('glass card renders inside themed app', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: Center(child: GlassCard(child: Text('Omi smoke test'))),
        ),
      ),
    );

    expect(find.text('Omi smoke test'), findsOneWidget);
    expect(find.byType(GlassCard), findsOneWidget);
  });
}
