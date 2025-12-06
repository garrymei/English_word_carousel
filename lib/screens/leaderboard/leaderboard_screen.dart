import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/points_service.dart';
import '../../services/leaderboard_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final _points = PointsService();
  final _svc = LeaderboardService();
  List<LeaderboardEntry> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final p = await _points.getPoints();
    final list = await _svc.global(auth, p['total'] ?? 0);
    setState(() {
      _list = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('排行榜')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = _list[i];
                final top3 = e.rank <= 3;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: top3 ? Colors.amber.shade700 : Colors.blueGrey.shade700,
                    child: Text('${e.rank}', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(e.username, style: TextStyle(color: e.isMe ? Colors.cyanAccent : Colors.white)),
                  subtitle: Text('积分：${e.score}', style: const TextStyle(color: Colors.white70)),
                  trailing: e.isMe ? const Icon(Icons.trending_up, color: Colors.cyanAccent) : null,
                );
              },
            ),
    );
  }
}