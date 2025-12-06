import 'package:shared_preferences/shared_preferences.dart';
import '../data/models/carousel_config.dart';
import 'audio_cache_service.dart';

class SettingsService {
  static const _kVoice = 'voice';
  static const _kAutoPlaySound = 'autoPlaySound';
  static const _kDurationMode = 'durationMode';
  static const _kIntervalSeconds = 'intervalSeconds';

  Future<CarouselConfig> loadConfig() async {
    final p = await SharedPreferences.getInstance();
    return CarouselConfig(
      voice: p.getString(_kVoice) ?? 'en-US',
      autoPlaySound: p.getBool(_kAutoPlaySound) ?? false,
      durationMode: p.getString(_kDurationMode) ?? 'forever',
      intervalSeconds: p.getInt(_kIntervalSeconds) ?? 5,
    );
  }

  Future<void> saveConfig(CarouselConfig c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kVoice, c.voice);
    await p.setBool(_kAutoPlaySound, c.autoPlaySound);
    await p.setString(_kDurationMode, c.durationMode);
    await p.setInt(_kIntervalSeconds, c.intervalSeconds);
  }

  Future<void> clearAudioCache() async {
    final svc = AudioCacheService();
    await svc.cleanCacheIfNeeded();
  }
}