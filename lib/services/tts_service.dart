import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();

  Future<void> init(String voice) async {
    await _tts.setLanguage(voice); // "en-US" / "en-GB"
    await _tts.setSpeechRate(0.4);
    await _tts.setPitch(1.0);
  }

  Future<Directory> _audioDir() async {
    if (kIsWeb) {
      throw UnsupportedError('TTS file cache directory not available on Web');
    }
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

  Future<File> generateAndCache(String word, String voice) async {
    await init(voice);
    if (kIsWeb) {
      // Web: 直接发音，不进行文件缓存
      await _tts.speak(word);
      // 返回一个占位 File 在 Web 不适用，避免调用方依赖返回值
      throw UnsupportedError('generateAndCache is not supported on Web');
    } else {
      final dir = await _audioDir();
      final file = File(p.join(dir.path, _safeName(word, voice)));
      if (await file.exists()) return file;
      try {
        await _tts.synthesizeToFile(word, file.path);
      } catch (_) {
        // 回退方案：直接 speak（不落盘）
        await _tts.speak(word);
      }
      return file;
    }
  }

  Future<void> speakDirect(String word, String voice) async {
    await init(voice);
    await _tts.speak(word);
  }
}