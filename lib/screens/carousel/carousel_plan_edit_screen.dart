import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/word_provider.dart';
import '../../providers/carousel_plan_provider.dart';
import '../../data/models/word_card.dart';

class CarouselPlanEditScreen extends StatefulWidget {
  const CarouselPlanEditScreen({super.key});

  @override
  State<CarouselPlanEditScreen> createState() => _CarouselPlanEditScreenState();
}

class _CarouselPlanEditScreenState extends State<CarouselPlanEditScreen> {
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _selectedWordIds = {};
  VoidCallback? _authListener;
  String? _lastUid;

  @override
  void initState() {
    super.initState();
    // 等待 Auth 就绪后再加载词卡，避免使用空用户导致候选列表不完整
    _authListener = () {
      final auth = context.read<AuthProvider>();
      if (auth.initializing) return;
      final uid = auth.userId;
      if (_lastUid == uid) return;
      _lastUid = uid;
      final words = context.read<WordProvider>();
      if (words.words.isEmpty) {
        words.loadWords(userId: uid);
      }
    };
    context.read<AuthProvider>().addListener(_authListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authListener!.call());
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    // 移除 AuthProvider 监听，避免内存泄漏
    if (_authListener != null) {
      context.read<AuthProvider>().removeListener(_authListener!);
      _authListener = null;
    }
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WordCard> _filtered(List<WordCard> list) {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return list;
    return list.where((w) =>
      w.word.toLowerCase().contains(q) ||
      w.chinese.toLowerCase().contains(q) ||
      (w.phonetic.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wordProv = context.watch<WordProvider>();
    final words = _filtered(wordProv.words);
    return Scaffold(
      appBar: AppBar(title: const Text('新建轮播方案')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: '方案名称'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    labelText: '搜索单词',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: wordProv.loading && wordProv.words.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: words.length,
                    itemBuilder: (_, i) {
                      final w = words[i];
                      final checked = _selectedWordIds.contains(w.id);
                      return CheckboxListTile(
                        title: Text(w.word),
                        subtitle: Text(w.chinese),
                        value: checked,
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selectedWordIds.add(w.id);
                            } else {
                              _selectedWordIds.remove(w.id);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _selectedWordIds
                        ..clear()
                        ..addAll(wordProv.words.map((e) => e.id));
                    }),
                    child: const Text('全选'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => _selectedWordIds.clear()),
                    child: const Text('清空'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = _nameCtrl.text.trim();
                  if (name.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入方案名称')));
                    return;
                  }
                  final auth = context.read<AuthProvider>();
                  final uid = auth.userId;
                  if (uid == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录后再保存方案')));
                    return;
                  }
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const Center(child: CircularProgressIndicator()),
                    );
                    final newId = await context
                        .read<CarouselPlanProvider>()
                        .create(name, userId: uid, wordIds: _selectedWordIds.toList());
                    if (context.mounted) {
                      Navigator.of(context).pop(); // close progress
                      Navigator.pop(context, newId);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.of(context).pop(); // close progress if open
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text('保存失败：$e')));
                    }
                  }
                },
                child: const Text('保存方案'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}