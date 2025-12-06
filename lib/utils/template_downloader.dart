import 'dart:typed_data';

import 'template_downloader_io.dart' if (dart.library.html) 'template_downloader_web.dart' as impl;

class TemplateDownloader {
  static Future<String> saveOrDownload(String filename, Uint8List bytes) {
    return impl.saveOrDownload(filename, bytes);
  }
}