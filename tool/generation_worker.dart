import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;
import 'package:papatte_parc/shared/generation/generation_protocol.dart';

@JS('self')
external web.DedicatedWorkerGlobalScope get workerScope;

void main() {
  workerScope.onmessage = ((web.MessageEvent event) {
    Map<String, Object?> response;
    try {
      final request = (jsonDecode((event.data as JSString).toDart) as Map)
          .cast<String, dynamic>();
      response = {'id': request['id'], 'result': executeGeneration(request)};
    } catch (error) {
      response = {'error': error.toString()};
    }
    workerScope.postMessage(jsonEncode(response).toJS);
  }).toJS;
}
