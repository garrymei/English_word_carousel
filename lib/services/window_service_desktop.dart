import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart' as acrylic;
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';

/// 桌面悬浮窗口服务（macOS/Windows），支持：置顶、隐藏、毛玻璃、托盘、全局热键、鼠标穿透
class WindowService with TrayListener {
  static final WindowService _instance = WindowService._internal();
  factory WindowService() => _instance;
  WindowService._internal();

  bool _inited = false;

  Future<void> init({Size size = const Size(520, 360)}) async {
    if (kIsWeb || _inited) return;
    WidgetsFlutterBinding.ensureInitialized();
    if (!Platform.isWindows && !Platform.isMacOS) return;

    await windowManager.ensureInitialized();

    final options = WindowOptions(
      size: size,
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: Platform.isWindows,
      titleBarStyle: Platform.isMacOS ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.setAlwaysOnTop(true);
      await windowManager.setHasShadow(true);
      await windowManager.show();
      await windowManager.focus();
    });

    // Acrylic/Mica/Blur 效果
    try {
      await acrylic.Window.initialize();
      await acrylic.Window.setEffect(
        // Windows 使用 Acrylic；macOS 选用 popover 等可用的毛玻璃材质
        effect: Platform.isWindows ? acrylic.WindowEffect.acrylic : acrylic.WindowEffect.popover,
        color: const Color(0x80FFFFFF),
      );
    } catch (_) {}

    // 托盘
    try {
      trayManager.addListener(this);
      await trayManager.setIcon('assets/icons/floating_icon.png');
      await trayManager.setContextMenu(
        Menu(items: [
          MenuItem(key: 'show', label: '显示'),
          MenuItem(key: 'hide', label: '隐藏'),
          MenuItem.separator(),
          MenuItem(key: 'prev', label: '上一张'),
          MenuItem(key: 'next', label: '下一张'),
          MenuItem.separator(),
          MenuItem(key: 'top', label: '置顶开关'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: '退出'),
        ]),
      );
    } catch (_) {}

    _inited = true;
  }

  Future<bool> showFloatingWindow() async {
    if (kIsWeb) return false;
    if (!Platform.isWindows && !Platform.isMacOS) return false;
    await windowManager.show();
    await windowManager.focus();
    return true;
  }

  Future<bool> hideFloatingWindow() async {
    if (kIsWeb) return false;
    if (!Platform.isWindows && !Platform.isMacOS) return false;
    await windowManager.hide();
    return true;
  }

  Future<bool> setAlwaysOnTop(bool value) async {
    if (kIsWeb) return false;
    if (!Platform.isWindows && !Platform.isMacOS) return false;
    await windowManager.setAlwaysOnTop(value);
    return true;
  }

  Future<bool> setIgnoreMouseEvents(bool value) async {
    if (kIsWeb) return false;
    if (!Platform.isWindows && !Platform.isMacOS) return false;
    await windowManager.setIgnoreMouseEvents(value);
    return true;
  }

  Future<void> setPosition(Offset p) async {
    if (!Platform.isWindows && !Platform.isMacOS) return;
    await windowManager.setPosition(Offset(p.dx, p.dy));
  }

  Future<void> setSize(Size s) async {
    if (!Platform.isWindows && !Platform.isMacOS) return;
    await windowManager.setSize(s);
  }

  // 全局热键
  Future<void> registerHotkeys({
    required VoidCallback onTogglePlay,
    required VoidCallback onPrev,
    required VoidCallback onNext,
    required VoidCallback onHide,
  }) async {
    if (!Platform.isWindows && !Platform.isMacOS) return;
    await hotKeyManager.unregisterAll();
    await hotKeyManager.register(
      HotKey(key: LogicalKeyboardKey.space, scope: HotKeyScope.system),
      keyDownHandler: (_) => onTogglePlay(),
    );
    await hotKeyManager.register(
      HotKey(key: LogicalKeyboardKey.arrowLeft, scope: HotKeyScope.system),
      keyDownHandler: (_) => onPrev(),
    );
    await hotKeyManager.register(
      HotKey(key: LogicalKeyboardKey.arrowRight, scope: HotKeyScope.system),
      keyDownHandler: (_) => onNext(),
    );
    await hotKeyManager.register(
      HotKey(key: LogicalKeyboardKey.escape, scope: HotKeyScope.system),
      keyDownHandler: (_) => onHide(),
    );
  }

  // 托盘事件
  @override
  void onTrayIconMouseDown() async {
    await showFloatingWindow();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await showFloatingWindow();
        break;
      case 'hide':
        await hideFloatingWindow();
        break;
      case 'prev':
        // 在入口处通过回调接入 Provider（此处留空）
        break;
      case 'next':
        // 在入口处通过回调接入 Provider（此处留空）
        break;
      case 'top':
        final isTop = await windowManager.isAlwaysOnTop();
        await setAlwaysOnTop(!isTop);
        break;
      case 'quit':
        exit(0);
      default:
    }
  }
}
