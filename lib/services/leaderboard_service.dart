import 'dart:math';
import '../providers/auth_provider.dart';

class LeaderboardEntry {
  final int rank;
  final String username;
  final int score;
  final bool isMe;
  LeaderboardEntry({required this.rank, required this.username, required this.score, this.isMe = false});
}

class LeaderboardService {
  Future<List<LeaderboardEntry>> global(AuthProvider auth, int myScore) async {
    // 生成示例榜单数据
    final names = ['Garry', 'Luna', 'Nova', 'Kai', 'Mira', 'Zoe', 'Rex'];
    final rng = Random();
    final list = List.generate(7, (i) => LeaderboardEntry(rank: i + 1, username: names[i], score: 900 + rng.nextInt(500)));
    // 插入自己
    final meName = auth.currentUser?.username ?? 'Me';
    list.add(LeaderboardEntry(rank: list.length + 1, username: meName, score: myScore, isMe: true));
    list.sort((a, b) => b.score.compareTo(a.score));
    for (int i = 0; i < list.length; i++) {
      list[i] = LeaderboardEntry(rank: i + 1, username: list[i].username, score: list[i].score, isMe: list[i].isMe);
    }
    return list;
  }
}