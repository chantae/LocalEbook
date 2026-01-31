import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

void debugLog({
  required String location,
  required String message,
  Map<String, Object?>? data,
  required String hypothesisId,
}) {
  if (!kIsWeb || !kDebugMode) {
    return;
  }
  final host = html.window.location.hostname;
  if (host != 'localhost' && host != '127.0.0.1') {
    return;
  }
  final payload = {
    'sessionId': 'debug-session',
    'runId': 'run1',
    'hypothesisId': hypothesisId,
    'location': location,
    'message': message,
    'data': data ?? const {},
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  };
  html.HttpRequest.request(
    'http://127.0.0.1:7242/ingest/bb4db911-7a2e-4946-9ac3-80ec831234ea',
    method: 'POST',
    sendData: jsonEncode(payload),
    requestHeaders: {'Content-Type': 'application/json'},
  ).catchError((_) {});
}
