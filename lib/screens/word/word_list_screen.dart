import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/word_provider.dart';
import '../../widgets/empty_state.dart';

class WordListScreen extends StatefulWidget {
  const WordListScreen({super.key});
  @override
  State<WordListScreen> createState() => _WordListScreenState();
}

class _WordListScreenState extends State<WordListScreen> {
  bool onlyEnabled = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<WordProvider>().loadWords());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<WordProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('单词卡列表'),
        actions: [
          Row(children: [
            const Text('只看启用'),
            Switch(
              value: onlyEnabled,
              onChanged: (v) async {
                setState(() => onlyEnabled = v);
                await provider.loadWords(onlyEnabled: onlyEnabled);
              },
            ),
          ])
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.words.isEmpty
              ? const EmptyState(message: '还没有单词卡，点击右下角 + 创建')
              : ListView.builder(
                  itemCount: provider.words.length,
                  itemBuilder: (context, i) {
                    final w = provider.words[i];
                    return ListTile(
                      title: Text('${w.word}  ${w.phonetic}'),
                      subtitle: Text(w.chinese),
                      trailing: Switch(
                        value: w.enabled,
                        onChanged: (v) => provider.toggleEnabled(w.id, v),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 跳转到编辑页（后续补充）
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('编辑页稍后补充')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}