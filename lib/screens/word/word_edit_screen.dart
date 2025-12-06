import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../providers/word_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/word_card.dart';
import '../../data/models/tag.dart';
import '../../data/repositories/tag_repository.dart';

class WordEditScreen extends StatefulWidget {
  final WordCard? initial;
  const WordEditScreen({super.key, this.initial});

  @override
  State<WordEditScreen> createState() => _WordEditScreenState();
}

class _WordEditScreenState extends State<WordEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();
  final _tagRepo = TagRepository();

  late TextEditingController _word;
  late TextEditingController _chinese;
  late TextEditingController _phonetic;
  late TextEditingController _phrase;
  late TextEditingController _phraseCn;
  late TextEditingController _sentenceEn;
  late TextEditingController _sentenceCn;
  late TextEditingController _tags;
  bool _enabled = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _word = TextEditingController(text: i?.word ?? '');
    _chinese = TextEditingController(text: i?.chinese ?? '');
    _phonetic = TextEditingController(text: i?.phonetic ?? '');
    _phrase = TextEditingController(text: i?.phrase ?? '');
    _phraseCn = TextEditingController(text: i?.phraseCn ?? '');
    _sentenceEn = TextEditingController(text: i?.sentenceEn ?? '');
    _sentenceCn = TextEditingController(text: i?.sentenceCn ?? '');
    _tags = TextEditingController();
    _enabled = i?.enabled ?? true;
  }

  @override
  void dispose() {
    _word.dispose();
    _chinese.dispose();
    _phonetic.dispose();
    _phrase.dispose();
    _phraseCn.dispose();
    _sentenceEn.dispose();
    _sentenceCn.dispose();
    _tags.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    bool ok = false;
    try {
      final uid = context.read<AuthProvider>().userId;
      final provider = context.read<WordProvider>();

      // 解析标签（DB 不可用时兜底为空）
      final names = _tags.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final tagIds = <String>{};
      try {
        final existing = await _tagRepo.listAll(userId: uid);
        final byName = {for (final t in existing) t.name.trim(): t};
        for (final name in names) {
          final t = byName[name];
          if (t != null) {
            tagIds.add(t.id);
          } else {
            final nt = Tag(id: _uuid.v4(), name: name, userId: uid);
            await _tagRepo.upsert(nt);
            tagIds.add(nt.id);
          }
        }
      } catch (_) {
        // Web 环境可能不支持本地 DB，跳过标签的持久化
      }

      if (widget.initial == null) {
        final w = WordCard(
          id: _uuid.v4(),
          word: _word.text.trim(),
          chinese: _chinese.text.trim(),
          phonetic: _phonetic.text.trim(),
          phrase: _phrase.text.trim(),
          phraseCn: _phraseCn.text.trim(),
          sentenceEn: _sentenceEn.text.trim(),
          sentenceCn: _sentenceCn.text.trim(),
          enabled: _enabled,
          tagIds: tagIds.toList(),
          userId: uid,
        );
        await provider.createWord(w);
      } else {
        final w = widget.initial!;
        w.word = _word.text.trim();
        w.chinese = _chinese.text.trim();
        w.phonetic = _phonetic.text.trim();
        w.phrase = _phrase.text.trim();
        w.phraseCn = _phraseCn.text.trim();
        w.sentenceEn = _sentenceEn.text.trim();
        w.sentenceCn = _sentenceCn.text.trim();
        w.enabled = _enabled;
        w.tagIds = tagIds.toList();
        w.userId = uid;
        await provider.updateWord(w);
      }
      ok = true;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }

    if (ok && mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? '新建单词卡' : '编辑单词卡'),
        actions: [
          IconButton(onPressed: _saving ? null : _save, icon: const Icon(Icons.save)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _word,
                decoration: const InputDecoration(labelText: '单词*'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: _chinese,
                decoration: const InputDecoration(labelText: '中文释义*'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '必填' : null,
              ),
              TextFormField(
                controller: _phonetic,
                decoration: const InputDecoration(labelText: '音标'),
              ),
              TextFormField(
                controller: _phrase,
                decoration: const InputDecoration(labelText: '短语'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _phraseCn,
                decoration: const InputDecoration(labelText: '短语中文'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _sentenceEn,
                decoration: const InputDecoration(labelText: '英文例句'),
                maxLines: 2,
              ),
              TextFormField(
                controller: _sentenceCn,
                decoration: const InputDecoration(labelText: '中文例句'),
                maxLines: 2,
              ),
              SwitchListTile(
                title: const Text('启用'),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
              TextFormField(
                controller: _tags,
                decoration: const InputDecoration(labelText: '标签（逗号分隔，可空）'),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving ? const Icon(Icons.hourglass_bottom) : const Icon(Icons.save),
                label: Text(_saving ? '保存中…' : '保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}