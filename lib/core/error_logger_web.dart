import 'dart:async';
import 'package:flutter/material.dart';

void setupErrorLogger() {
  FlutterError.onError = (FlutterErrorDetails details) async {
    final msg = details.exceptionAsString();
    final stack = details.stack?.toString() ?? '';
    // 在 Web 端仅打印到控制台，避免使用文件系统
    // ignore: avoid_print
    print('FlutterError: $msg\n$stack');
    FlutterError.presentError(details);
  };
  runZonedGuarded(() {}, (error, stack) async {
    // ignore: avoid_print
    print('ZoneError: ${error.toString()}\n${stack.toString()}');
  });
}