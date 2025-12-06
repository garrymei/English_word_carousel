import 'package:flutter/services.dart';
import '../../providers/carousel_provider.dart';

class FloatingController {
  final CarouselProvider provider;
  FloatingController(this.provider);

  void handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) return;
    final keyLabel = event.logicalKey.keyLabel;
    switch (keyLabel) {
      case ' ':
        provider.isPlaying ? provider.pause() : provider.start();
        break;
      case 'Arrow Left':
        provider.prev();
        break;
      case 'Arrow Right':
        provider.next();
        break;
      case 'Escape':
        // 关闭在屏幕侧处理
        break;
      default:
        break;
    }
  }
}
