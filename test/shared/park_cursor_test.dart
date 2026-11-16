import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:papatte_parc/shared/park_cursor.dart';

void main() {
  testWidgets('mouse pointer follows movement without blocking controls', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ParkCursor(
          child: Center(
            child: TextButton(onPressed: () => taps++, child: const Text('Go')),
          ),
        ),
      ),
    );

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(10, 10));
    await mouse.moveTo(tester.getCenter(find.text('Go')));
    await tester.pump();
    final cursor = find.byKey(const ValueKey('park-cursor'));
    expect(
      tester.getTopLeft(cursor) + const Offset(3.2, .3),
      tester.getCenter(find.text('Go')),
    );
    expect(tester.getSize(cursor), const Size(26, 26));
    expect(
      RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
      SystemMouseCursors.none,
    );
    await mouse.down(tester.getCenter(find.text('Go')));
    await mouse.moveTo(tester.getCenter(find.text('Go')) + const Offset(1, 0));
    await tester.pump();
    expect(
      tester.getTopLeft(cursor) + const Offset(3.2, .3),
      tester.getCenter(find.text('Go')) + const Offset(1, 0),
    );
    await mouse.up();
    await tester.pump();
    expect(taps, 1);
    await mouse.removePointer();
    await tester.pump();
    expect(cursor, findsNothing);
  });
}
