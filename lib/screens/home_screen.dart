import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/word/word_list_screen.dart';
import '../screens/tag/tag_list_screen.dart';
import '../screens/carousel/carousel_player_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../providers/auth_provider.dart';
import '../screens/plan/study_plan_screen.dart';
import '../screens/ai/ai_recommend_screen.dart';
import '../screens/speech/speech_practice_screen.dart';
import '../screens/leaderboard/leaderboard_screen.dart';
import '../screens/group/group_screen.dart';
import '../screens/challenge/challenge_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'profile_screen.dart';
import '../providers/word_provider.dart';
import '../providers/tag_provider.dart';
import '../providers/carousel_provider.dart';
import 'package:english_word_carousel/screens/floating/floating_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final loggedIn = auth.currentUser != null;
    final displayName = loggedIn
        ? (auth.currentUser!.username ?? auth.currentUser!.email.split('@').first)
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('English Word Carousel')),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1220),
                    Color(0xFF111827),
                  ],
                ),
              ),
            ),
          ),
          ListView(
            children: [
          if (loggedIn) ...[
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text('已登录：${displayName}'),
              subtitle: Text(auth.currentUser!.email),
              trailing: TextButton(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                  // 清理本地状态
                  context.read<WordProvider>().clear();
                  context.read<TagProvider>().clear();
                  context.read<CarouselProvider>().reset();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: const Text('退出登录'),
              ),
            ),
            _Tile(
              title: '个人信息',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]
          else ...[
            _Tile(
              title: '登录',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
            _Tile(
              title: '注册',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
            ),
          ],
          const Divider(),
          _Tile(
            title: '轮播播放',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CarouselPlayerScreen())),
          ),
          _Tile(
            title: '设置',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          _Tile(
            title: '单词卡',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WordListScreen())),
          ),
          _Tile(
            title: '学习计划',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const StudyPlanScreen())),
          ),
          _Tile(
            title: 'AI 推荐',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AIRecommendScreen())),
          ),
          _Tile(
            title: '悬浮轮播助手预览',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const FloatingPlayerScreen())),
          ),
          _Tile(
            title: '标签管理',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TagListScreen())),
          ),
          _Tile(
            title: '口语评测',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const SpeechPracticeScreen())),
          ),
          _Tile(
            title: '排行榜',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const LeaderboardScreen())),
          ),
          _Tile(
            title: '学习组',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const GroupScreen())),
          ),
          _Tile(
            title: '挑战赛',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const ChallengeScreen())),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _Tile({required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
