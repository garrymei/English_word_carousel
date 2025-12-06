import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/study_plan_provider.dart';
import '../../data/models/study_plan.dart';

class StudyPlanScreen extends StatefulWidget {
  const StudyPlanScreen({super.key});

  @override
  State<StudyPlanScreen> createState() => _StudyPlanScreenState();
}

class _StudyPlanScreenState extends State<StudyPlanScreen> {
  final _targetCtrl = TextEditingController();
  final _cycleCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  bool _loading = true;
  String? _lastUid;
  VoidCallback? _authListener;

  @override
  void initState() {
    super.initState();
    // 监听身份就绪后再加载学习计划，避免回退到调试用户或空 userId
    _authListener = () {
      final auth = context.read<AuthProvider>();
      print('StudyPlanScreen: Auth listener called. Initializing: ${auth.initializing}, userId: ${auth.userId}');
      if (auth.initializing) return;
      final uid = auth.userId;
      if (uid == null) {
        print('StudyPlanScreen: No userId available, skipping load.');
        // 未登录：保持加载中提示或可根据需要展示空态
        return;
      }
      if (_lastUid == uid) return;
      _lastUid = uid;
      print('StudyPlanScreen: Loading plan for userId: $uid');
      final p = context.read<StudyPlanProvider>();
      p.load(uid).then((_) {
        final plan = p.plan!;
        _targetCtrl.text = plan.targetWords.toString();
        _cycleCtrl.text = plan.reviewCycleDays.toString();
        _timeCtrl.text = plan.reminderTime;
        if (mounted) {
          setState(() => _loading = false);
          print('StudyPlanScreen: Load completed. Plan: targetWords=${plan.targetWords}, todayCount=${p.todayCount}');
        }
      }).catchError((e) {
        print('StudyPlanScreen: Error loading plan: $e');
      });
    };
    context.read<AuthProvider>().addListener(_authListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authListener!.call());
  }

  @override
  void dispose() {
    _targetCtrl.dispose();
    _cycleCtrl.dispose();
    _timeCtrl.dispose();
    if (_authListener != null) {
      context.read<AuthProvider>().removeListener(_authListener!);
    }
    super.dispose();
  }

  Future<void> _save() async {
    final p = context.read<StudyPlanProvider>();
    final uid = context.read<AuthProvider>().userId;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录后再保存学习计划')));
      return;
    }
    final plan = p.plan ?? StudyPlan(userId: uid);
    plan.targetWords = int.tryParse(_targetCtrl.text) ?? plan.targetWords;
    plan.reviewCycleDays = int.tryParse(_cycleCtrl.text) ?? plan.reviewCycleDays;
    plan.reminderTime = _timeCtrl.text.trim();
    await p.save(plan);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已保存学习计划')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<StudyPlanProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('学习计划')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _targetCtrl,
                    decoration: const InputDecoration(labelText: '每日目标单词数'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _cycleCtrl,
                    decoration: const InputDecoration(labelText: '复习周期（天）'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _timeCtrl,
                    decoration: const InputDecoration(labelText: '提醒时间（HH:mm）'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(onPressed: _save, child: const Text('保存')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await p.refreshToday(context.read<AuthProvider>().userId);
                        },
                        child: const Text('刷新今日进度'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('今日完成：${p.todayCount}/${p.plan?.targetWords ?? 0}'),
                 const SizedBox(height: 8),
                 LinearProgressIndicator(value: (p.plan?.targetWords ?? 0) == 0 ? 0 : (p.todayCount / (p.plan!.targetWords)), minHeight: 8),
                 const SizedBox(height: 16),
                 Text('连胜天数：${p.plan?.streakDays ?? 0} 天'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await p.markCompleted(true);
                          if (mounted) {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('成就达成'),
                                content: const Text('已完成今日目标，继续保持！🏆'),
                                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('好的'))],
                              ),
                            );
                          }
                        },
                        child: const Text('打卡完成'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => p.markCompleted(false),
                        child: const Text('取消打卡'),
                      ),
                    ],
                  ),
                 const SizedBox(height: 20),
                 Text('最近7天'),
                 const SizedBox(height: 8),
                 Expanded(
                   child: ListView.separated(
                     itemCount: p.history.length,
                     separatorBuilder: (_, __) => const Divider(height: 1),
                     itemBuilder: (ctx, i) {
                       final h = p.history[i];
                       return ListTile(
                         dense: true,
                         title: Text('${h['date']}'),
                         subtitle: Text('完成数：${h['count']}'),
                         trailing: Text(h['completed'] ? '已完成' : '未完成', style: TextStyle(color: h['completed'] ? Colors.green : Colors.orange)),
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