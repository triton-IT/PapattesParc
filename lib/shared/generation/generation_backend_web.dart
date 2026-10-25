import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<Map<String, dynamic>> generateInBackground(
  Map<String, dynamic> request,
) async {
  final completer = Completer<Map<String, dynamic>>();
  final worker = web.Worker(
    web.URL('generation_worker.js', web.document.baseURI).href.toJS,
  );
  worker.onmessage = ((web.MessageEvent event) {
    try {
      final response = (jsonDecode((event.data as JSString).toDart) as Map)
          .cast<String, dynamic>();
      if (response['error'] != null) {
        completer.completeError(StateError(response['error'] as String));
      } else {
        completer.complete((response['result'] as Map).cast<String, dynamic>());
      }
    } catch (error, stack) {
      completer.completeError(error, stack);
    }
  }).toJS;
  worker.onerror = ((web.Event _) {
    if (!completer.isCompleted) {
      completer.completeError(
        StateError('Le générateur ne peut pas être chargé. Réessaie.'),
      );
    }
  }).toJS;
  try {
    worker.postMessage(jsonEncode(request).toJS);
    return await completer.future.timeout(const Duration(seconds: 120));
  } finally {
    worker.terminate();
  }
}
