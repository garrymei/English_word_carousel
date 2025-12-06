import 'package:flutter/material.dart';

class PlayerCard extends StatelessWidget {
  final String word;
  final String phonetic;
  final String chinese;
  final bool isPlaying;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPlayPause;
  final double progress; // 0..1

  const PlayerCard({
    super.key,
    required this.word,
    required this.phonetic,
    required this.chinese,
    required this.isPlaying,
    required this.onPrev,
    required this.onNext,
    required this.onPlayPause,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.4), width: 2),
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent.withValues(alpha: 0.25), blurRadius: 20, spreadRadius: 2),
        ],
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(word, style: const TextStyle(fontSize: 28, color: Colors.white)),
          const SizedBox(height: 6),
          Text(phonetic, style: const TextStyle(fontSize: 18, color: Colors.white70)),
          const SizedBox(height: 10),
          Text(chinese, style: const TextStyle(fontSize: 16, color: Colors.white)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white), onPressed: onPrev),
              const SizedBox(width: 12),
              IconButton(icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white), onPressed: onPlayPause),
              const SizedBox(width: 12),
              IconButton(icon: const Icon(Icons.skip_next, color: Colors.white), onPressed: onNext),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            color: Colors.cyanAccent,
            backgroundColor: Colors.white24,
          ),
        ],
      ),
    );
  }
}
