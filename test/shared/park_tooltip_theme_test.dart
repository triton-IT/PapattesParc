import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/app_theme.dart';

void main() {
  testWidgets('les infobulles utilisent le parchemin et restent visibles', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final topKey = GlobalKey<TooltipState>();
    final bottomKey = GlobalKey<TooltipState>();
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: Tooltip(
                  key: topKey,
                  message: 'Retour',
                  child: const SizedBox.square(dimension: 48),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Tooltip(
                  key: bottomKey,
                  message: 'Agrandir le plateau',
                  child: const SizedBox.square(dimension: 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final theme = TooltipTheme.of(tester.element(find.byKey(topKey)));
    expect(theme.textStyle?.color, const Color(0xff563619));
    expect(theme.decoration, isA<BoxDecoration>());

    topKey.currentState!.ensureTooltipVisible();
    await tester.pumpAndSettle();
    final topLabel = tester.getRect(find.text('Retour', findRichText: true));
    expect(topLabel.top, greaterThanOrEqualTo(0));
    expect(topLabel.bottom, lessThanOrEqualTo(568));
    expect(topLabel.left, greaterThanOrEqualTo(0));
    expect(topLabel.right, lessThanOrEqualTo(320));
    expect(topLabel.top, greaterThan(48));

    Tooltip.dismissAllToolTips();
    await tester.pumpAndSettle();
    bottomKey.currentState!.ensureTooltipVisible();
    await tester.pumpAndSettle();
    final bottomLabel = tester.getRect(
      find.text('Agrandir le plateau', findRichText: true),
    );
    expect(bottomLabel.top, greaterThanOrEqualTo(0));
    expect(bottomLabel.bottom, lessThan(520));
    expect(bottomLabel.left, greaterThanOrEqualTo(0));
    expect(bottomLabel.right, lessThanOrEqualTo(320));
  });
}
