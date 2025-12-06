import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class SpeechScore {
  final int accuracy;
  final int fluency;
  final int intonation;
  final int score;
  final String feedback;
  SpeechScore({
    required this.accuracy,
    required this.fluency,
    required this.intonation,
    required this.score,
    required this.feedback,
  });
}

/// 占位语音评测服务：后续接入录音与后端评测接口
class SpeechService {
  bool _recording = false;

  bool get isRecording => _recording;

  Future<void> startRecording() async {
    // TODO: 集成 flutter_record 或类似插件
    _recording = true;
  }

  Future<SpeechScore> stopAndEvaluate({required String word}) async {
    _recording = false;
    // 模拟评分：基于词长度与时间扰动生成稳定但有波动的分数
    final t = DateTime.now().millisecondsSinceEpoch;
    final base = max(60, min(95, 70 + word.length));
    int accuracy = ((base + (t % 11) - 5)).clamp(0, 100);
    int fluency = ((base - 5 + (t % 9) - 4)).clamp(0, 100);
    int intonation = ((base - 10 + (t % 7) - 3)).clamp(0, 100);
    int score = ((accuracy * 0.5) + (fluency * 0.3) + (intonation * 0.2)).round();

    final feedback = score >= 80
        ? 'Great! 保持当前节奏与语调。'
        : '建议放慢语速，注意重音与连读。';

    // 写入本地最近一次评测结果（用于积分联动）
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_speech_score', score);
    await prefs.setString('last_speech_word', word);

    return SpeechScore(
      accuracy: accuracy,
      fluency: fluency,
      intonation: intonation,
      score: score,
      feedback: feedback,
    );
  }
}