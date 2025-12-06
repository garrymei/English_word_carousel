import 'error_logger_io.dart' if (dart.library.html) 'error_logger_web.dart' as impl;

void setupErrorLogger() {
  impl.setupErrorLogger();
}