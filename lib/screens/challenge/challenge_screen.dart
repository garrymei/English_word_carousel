import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChallengeScreen extends StatefulWidget {
  const ChallengeScreen({super.key});

  @override
  State<ChallengeScreen> createState() => _ChallengeScreenState();
}

class _ChallengeScreenState extends State<ChallengeScreen> {
  static const _prefKeyStart = 'challenge_start';
  DateTime? _start;
  int _durationDays = 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_prefKeyStart);
    setState(() { _start = s != null ? DateTime.tryParse(s) : null; });
  }

  Future<void> _startChallenge() async {
    final now = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyStart, now.toIso8601String());
    setState(() { _start = now; });
  }

  Future<void> _endChallenge() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyStart);
    setState(() { _start = null; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('挑战赛已结算，积分与徽章将更新（示例）')),
      );
    }
  }

  int get _daysLeft {
    if (_start == null) return 0;
    final end = _start!.add(Duration(days: _durationDays));
    final diff = end.difference(DateTime.now()).inDays;
    return diff.clamp(0, _durationDays);
  }

  @override
  Widget build(BuildContext context) {
    final running = _start != null;
    return Scaffold(
      appBar: AppBar(title: const Text('挑战赛')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('7 天挑战赛', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('比拼学习时长 + 发音分数，结束后自动结算积分与徽章'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        ElevatedButton.icon(
                          onPressed: running ? null : _startChallenge,
                          icon: const Icon(Icons.flag),
                          label: const Text('开始挑战'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: running ? _endChallenge : null,
                          icon: const Icon(Icons.emoji_events),
                          label: const Text('结算挑战'),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<int>(
                          value: _durationDays,
                          items: const [7, 14].map((d) => DropdownMenuItem(value: d, child: Text('$d 天'))).toList(),
                          onChanged: running ? null : (v) => setState(() => _durationDays = v ?? 7),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(running ? '剩余天数：$_daysLeft 天' : '尚未开始'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('参与成员（示例）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    _ParticipantRow(name: '你', points: 120, score: 86),
                    _ParticipantRow(name: 'Alice', points: 140, score: 90),
                    _ParticipantRow(name: 'Bob', points: 95, score: 78),
                    _ParticipantRow(name: 'Carol', points: 110, score: 83),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('奖励规则（示例）', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('• 每次评测得分 ≥ 80 奖励 10 积分'),
                    Text('• 连续 7 天参与额外徽章'),
                    Text('• Top 3 额外加成'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantRow extends StatelessWidget {
  final String name;
  final int points;
  final int score;
  const _ParticipantRow({required this.name, required this.points, required this.score});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blueAccent,
            child: Text(name.characters.first.toUpperCase(), style: const TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          _NeonRing(value: score / 100.0),
          const SizedBox(width: 12),
          Text('积分 $points'),
        ],
      ),
    );
  }
}

class _NeonRing extends StatelessWidget {
  final double value;
  const _NeonRing({required this.value});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            backgroundColor: Colors.white24,
          ),
          Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}