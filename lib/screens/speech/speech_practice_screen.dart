import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carousel_provider.dart';
import '../../services/speech_service.dart';
import '../../services/points_service.dart';

class SpeechPracticeScreen extends StatefulWidget {
  const SpeechPracticeScreen({super.key});

  @override
  State<SpeechPracticeScreen> createState() => _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends State<SpeechPracticeScreen> with SingleTickerProviderStateMixin {
  late final SpeechService _svc;
  bool _recording = false;
  SpeechScore? _last;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _svc = SpeechService();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final provider = context.read<CarouselProvider>();
      final current = provider.playingDeck.isNotEmpty ? provider.playingDeck[provider.currentIndex] : null;
      final word = current?.word ?? 'resilient';
      final result = await _svc.stopAndEvaluate(word: word);
      setState(() {
        _recording = false;
        _last = result;
      });
      if (result.score >= 80) {
        await PointsService().addPoints(10);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('评测达标，积分 +10')),
          );
        }
      }
    } else {
      await _svc.startRecording();
      setState(() { _recording = true; });
    }
  }

  Widget _scoreCircle(String label, int value, Color color) {
    return Column(
      children: [
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(value: value / 100, strokeWidth: 8, color: color, backgroundColor: Colors.white24),
              Text('$value', style: const TextStyle(color: Colors.white, fontSize: 18)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<CarouselProvider>();
    final current = p.playingDeck.isEmpty ? null : p.playingDeck[p.currentIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('口语评测')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (current != null) ...[
                  Text(current.word, style: const TextStyle(color: Colors.white, fontSize: 28)),
                  const SizedBox(height: 6),
                  Text(current.phonetic, style: const TextStyle(color: Colors.white70)),
                ] else ...[
                  const Text('未加载词卡，使用示例词 resilient', style: TextStyle(color: Colors.white70)),
                ],
                const SizedBox(height: 24),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _recording
                        ? Colors.redAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: _recording ? 0.5 : 0.25),
                        blurRadius: _recording ? 30 : 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      ScaleTransition(
                        scale: Tween<double>(begin: 0.95, end: 1.05).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut)),
                        child: Icon(_recording ? Icons.mic : Icons.mic_none, color: Colors.white, size: 48),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _toggleRecord,
                        icon: Icon(_recording ? Icons.stop : Icons.mic, color: Colors.white),
                        label: Text(_recording ? '停止并评测' : '开始录音', style: const TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(backgroundColor: _recording ? Colors.redAccent : Colors.teal),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_last != null) ...[
                  Wrap(
                    spacing: 24,
                    runSpacing: 16,
                    alignment: WrapAlignment.center,
                    children: [
                      _scoreCircle('准确度', _last!.accuracy, Colors.cyanAccent),
                      _scoreCircle('流畅度', _last!.fluency, Colors.lightBlueAccent),
                      _scoreCircle('音调', _last!.intonation, Colors.indigoAccent),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('综合得分：${_last!.score}', style: const TextStyle(color: Colors.white, fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(_last!.feedback, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      // 再试一次
                      await _svc.startRecording();
                      setState(() { _recording = true; _last = null; });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade700),
                    child: const Text('再试一次', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
