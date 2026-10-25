import 'dart:isolate';
import 'generation_protocol.dart';

Future<Map<String, dynamic>> generateInBackground(
  Map<String, dynamic> request,
) => Isolate.run(() => executeGeneration(request));
