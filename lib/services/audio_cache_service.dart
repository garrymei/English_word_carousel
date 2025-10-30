import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AudioCacheService {
  static const maxCacheBytes = 500 * 1024 * 1024; // 500MB
  static const targetBytesAfterTrim = 400 * 1024 * 1024; // 400MB
  static const expiryDays = 30;

  Future<Directory> _cacheDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, 'cache', 'audio'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> filenameFor(String word, String voiceCode) async {
    // Normalize word to safe filename
    final safe = word.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safe}_${voiceCode}.mp3';
  }

  Future<File> fileFor(String word, String voiceCode) async {
    final dir = await _cacheDir();
    final name = await filenameFor(word, voiceCode);
    return File(p.join(dir.path, name));
  }

  Future<bool> exists(String word, String voiceCode) async {
    final f = await fileFor(word, voiceCode);
    return f.existsSync();
  }

  Future<void> touchAccess(File f) async {
    try {
      // Update modified time by writing zero bytes append
      await f.setLastModified(DateTime.now());
    } catch (_) {
      // ignore
    }
  }

  Future<void> cleanCacheIfNeeded() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return;
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    // Delete expired by age first
    final now = DateTime.now();
    for (final f in files) {
      final modified = f.statSync().modified;
      if (now.difference(modified).inDays >= expiryDays) {
        try { f.deleteSync(); } catch (_) {}
      }
    }

    // Recompute size
    final remaining = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    var size = remaining.fold<int>(0, (s, f) => s + f.lengthSync());
    if (size > maxCacheBytes) {
      for (final f in remaining) {
        if (size <= targetBytesAfterTrim) break;
        try {
          size -= f.lengthSync();
          f.deleteSync();
        } catch (_) {
          // ignore delete errors
        }
      }
    }
  }
}