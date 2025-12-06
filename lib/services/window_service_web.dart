import 'package:flutter/material.dart';

/// Web 空实现：保留同名 API，全部为 no-op，保证 Web 编译通过
class WindowService {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  Future<void> init({Size size = const Size(520, 360)}) async {}
  Future<bool> showFloatingWindow() async => false;
  Future<bool> hideFloatingWindow() async => false;
  Future<bool> setAlwaysOnTop(bool value) async => false;
  Future<bool> setIgnoreMouseEvents(bool value) async => false;
  Future<void> setPosition(Offset p) async {}
  Future<void> setSize(Size s) async {}
  Future<void> registerHotkeys({
    required VoidCallback onTogglePlay,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required VoidCallback onHide,
  }) async {}
}
