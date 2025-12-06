import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/ai_recommendation_service.dart';
import '../../data/models/word_card.dart';
import '../../providers/auth_provider.dart';
import '../../providers/carousel_provider.dart';
import '../carousel/carousel_player_screen.dart';

class AIRecommendScreen extends StatefulWidget {
  const AIRecommendScreen({super.key});

  @override
  State<AIRecommendScreen> createState() => _AIRecommendScreenState();
}

class _AIRecommendScreenState extends State<AIRecommendScreen> {
  final _svc = AIRecommendationService();
  bool _loading = true;
  List<WordCard> _words = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = context.read<AuthProvider>().userId ?? 'debug-user-id';
    // 目前三个类型都用本地启发式；后续根据类型切换不同策略或服务端接口
    final list = await _svc.recommendLocally(userId: uid, limit: 20);
    setState(() {
      _words = list;
      _selectedIds.clear();
      _loading = false;
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIds.length == _words.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(_words.map((w) => w.id));
      }
    });
  }

  Future<void> _addToCarouselAndPlay({bool startNow = true}) async {
    final selected = _words.where((w) => _selectedIds.contains(w.id)).toList();
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先选择要加入的单词')));
      return;
    }
    final provider = context.read<CarouselProvider>();
    provider.setDeck(selected, startPlaying: startNow);
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CarouselPlayerScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI 推荐'),
          bottom: TabBar(
            tabs: const [
              Tab(text: '综合'),
              Tab(text: '易错'),
              Tab(text: '相似'),
            ],
            onTap: (i) async {
              await _load();
            },
          ),
        ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.select_all),
                        label: Text(_selectedIds.length == _words.length ? '取消全选' : '全选'),
                        onPressed: _toggleSelectAll,
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.queue_play_next),
                        label: const Text('加入轮播并播放'),
                        onPressed: () => _addToCarouselAndPlay(startNow: true),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.playlist_add),
                        label: const Text('仅加入轮播'),
                        onPressed: () => _addToCarouselAndPlay(startNow: false),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    itemCount: _words.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final w = _words[i];
                      final selected = _selectedIds.contains(w.id);
                      return ListTile(
                        leading: Checkbox(
                          value: selected,
                          onChanged: (val) => setState(() {
                            if (val == true) {
                              _selectedIds.add(w.id);
                            } else {
                              _selectedIds.remove(w.id);
                            }
                          }),
                        ),
                        title: Text(w.word),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (w.phonetic.isNotEmpty) Text(w.phonetic),
                            if (w.chinese.isNotEmpty) Text(w.chinese),
                            Text('理由：久未复习优先'),
                            Text('难度：中'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () {
                            setState(() { _selectedIds.add(w.id); });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
