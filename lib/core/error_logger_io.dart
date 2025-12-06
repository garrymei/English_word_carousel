import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class _FileLogger {
  static Future<void> log(String message) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logsDir = Directory('${dir.path}/logs');
      if (!await logsDir.exists()) {
        await logsDir.create(recursive: true);
      }
      final date = DateTime.now();
      final file = File('${logsDir.path}/error_${date.year}${date.month.toString().padLeft(2,'0')}${date.day.toString().padLeft(2,'0')}.txt');
      final ts = date.toIso8601String();
      await file.writeAsString('[$ts] $message\n', mode: FileMode.append);
    } catch (_) {
      // ignore file errors to avoid cascading failures
    }
  }
}

void setupErrorLogger() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    final msg = details.exceptionAsString();
    final stack = details.stack?.toString() ?? '';
    await _FileLogger.log('FlutterError: $msg\n$stack');
    FlutterError.presentError(details);
  };
  runZonedGuarded(() {}, (error, stack) async {
    await _FileLogger.log('ZoneError: ${error.toString()}\n${stack.toString()}');
  });
}