import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tag_provider.dart';
import '../../data/models/tag.dart';
import '../../widgets/empty_state.dart';

class TagListScreen extends StatefulWidget {
  const TagListScreen({super.key});
  @override
  State<TagListScreen> createState() => _TagListScreenState();
}

class _TagListScreenState extends State<TagListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<TagProvider>().loadTags());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TagProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('标签管理')),
      body: provider.tags.isEmpty
          ? const EmptyState(message: '还没有标签，点击右下角 + 创建')
          : ListView.builder(
              itemCount: provider.tags.length,
              itemBuilder: (context, i) {
                final t = provider.tags[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: _parseColor(t.color)),
                    title: Text(t.name),
                    subtitle: Text(t.description),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // 简易新建弹窗
          final res = await showDialog<Tag>(
            context: context,
            builder: (_) => _TagEditDialog(),
          );
          if (res != null) {
            await provider.create(res);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _parseColor(String hex) {
    final v = hex.replaceAll('#', '');
    return Color(int.parse('FF$v', radix: 16));
  }
}

class _TagEditDialog extends StatefulWidget {
  @override
  State<_TagEditDialog> createState() => _TagEditDialogState();
}

class _TagEditDialogState extends State<_TagEditDialog> {
  final nameCtrl = TextEditingController();
  final colorCtrl = TextEditingController(text: '#3B82F6');
  final descCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建标签'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '名称')),
            TextField(controller: colorCtrl, decoration: const InputDecoration(labelText: '颜色(#RRGGBB)')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: '描述')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () {
            final t = Tag(id: DateTime.now().millisecondsSinceEpoch.toString(), name: nameCtrl.text.trim(), color: colorCtrl.text.trim(), description: descCtrl.text.trim());
            Navigator.pop(context, t);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}