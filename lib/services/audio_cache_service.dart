import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../data/models/word_card.dart';
import 'tts_service.dart';

class AudioCacheService {
  static const maxCacheBytes = 500 * 1024 * 1024; // 500MB
  static const targetBytesAfterTrim = 400 * 1024 * 1024; // 400MB
  static const expiryDays = 30;

  final AudioPlayer _player = AudioPlayer();
  final TtsService _tts = TtsService();

  Future<Directory> _cacheDir() async {
    final base = await getApplicationCacheDirectory();
    final dir = Directory(p.join(base.path, 'audio'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _safeName(String word, String voice) {
    final safeWord = word.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final safeVoice = voice.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return '${safeWord}_${safeVoice}.mp3';
  }

  Future<File> _fileFor(String word, String voiceCode) async {
    final dir = await _cacheDir();
    return File(p.join(dir.path, _safeName(word, voiceCode)));
  }

  Future<void> playWord(WordCard w, String voice) async {
    final f = await _fileFor(w.word, voice);
    if (await f.exists()) {
      await _player.stop();
      await _player.play(DeviceFileSource(f.path));
      await _touchAccess(f);
    } else {
      final newFile = await _tts.generateAndCache(w.word, voice);
      await _player.stop();
      await _player.play(DeviceFileSource(newFile.path));
    }
    // 后台执行缓存清理
    cleanCacheIfNeeded();
  }

  Future<void> preloadDeck(List<WordCard> deck, String voice) async {
    for (final w in deck) {
      try { await _tts.generateAndCache(w.word, voice); } catch (_) {}
    }
  }

  Future<void> _touchAccess(File f) async {
    try {
      await f.setLastModified(DateTime.now());
    } catch (_) {}
  }

  Future<void> cleanCacheIfNeeded() async {
    final dir = await _cacheDir();
    if (!await dir.exists()) return;
    final files = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));

    // 删除过期
    final now = DateTime.now();
    for (final f in files) {
      final modified = f.statSync().modified;
      if (now.difference(modified).inDays >= expiryDays) {
        try { f.deleteSync(); } catch (_) {}
      }
    }

    // LRU 修剪
    final remaining = dir.listSync().whereType<File>().toList()
      ..sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    var size = remaining.fold<int>(0, (s, f) => s + f.lengthSync());
    if (size > maxCacheBytes) {
      for (final f in remaining) {
        if (size <= targetBytesAfterTrim) break;
        try {
          size -= f.lengthSync();
          f.deleteSync();
        } catch (_) {}
      }
    }
  }
}