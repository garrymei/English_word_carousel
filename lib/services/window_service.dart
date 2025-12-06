// 平台条件导出：桌面实现 vs Web 空实现
export 'window_service_desktop.dart' if (dart.library.html) 'window_service_web.dart';