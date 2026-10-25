import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() main) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global/events'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (call) async {
        final arguments = (call.arguments as Map?) ?? {};
        final id = arguments['playerId'];
        final eventChannel = 'xyz.luan/audioplayers/events/$id';
        if (call.method == 'create') {
          messenger.setMockMethodCallHandler(
            MethodChannel(eventChannel),
            (_) async => null,
          );
        }
        if (call.method == 'setSourceUrl' || call.method == 'setSourceBytes') {
          await messenger.handlePlatformMessage(
            eventChannel,
            const StandardMethodCodec().encodeSuccessEnvelope({
              'event': 'audio.onPrepared',
              'value': true,
            }),
            (_) {},
          );
        }
        if (call.method == 'getCurrentPosition' ||
            call.method == 'getDuration') {
          return 0;
        }
        return null;
      },
    );
  });
  await main();
}
