import 'package:flutter/material.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});
  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final List<String> _groups = ['Alpha 学习组', 'Beta 学习组'];

  void _createGroup() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('创建学习组'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: '组名')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('创建')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() { _groups.add(name); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('学习组')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.group_add),
                    label: const Text('创建小组'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.groups),
                    label: const Text('加入小组'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                itemCount: _groups.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final name = _groups[i];
                  return ListTile(
                    leading: const Icon(Icons.group, color: Colors.cyanAccent),
                    title: Text(name, style: const TextStyle(color: Colors.white)),
                    subtitle: const Text('共享计划与组内榜单', style: TextStyle(color: Colors.white70)),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('进入组榜'),
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