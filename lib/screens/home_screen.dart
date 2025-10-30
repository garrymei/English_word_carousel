import 'package:flutter/material.dart';
import '../screens/word/word_list_screen.dart';
import '../screens/tag/tag_list_screen.dart';
import '../screens/carousel/carousel_player_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('English Word Carousel')),
      body: ListView(
        children: [
          _Tile(
            title: '轮播播放',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const CarouselPlayerScreen())),
          ),
          _Tile(
            title: '单词卡',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WordListScreen())),
          ),
          _Tile(
            title: '标签管理',
            onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const TagListScreen())),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const _Tile({required this.title, required this.onTap, super.key});
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}