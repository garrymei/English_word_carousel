import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/carousel_provider.dart';
import '../../providers/auth_provider.dart';
import '../../data/models/word_card.dart';
import '../settings/settings_screen.dart';
import '../../providers/study_plan_provider.dart';
import '../../data/models/study_plan.dart';
import '../../data/models/carousel_config.dart';
import '../../providers/carousel_plan_provider.dart';
import '../../data/models/carousel_plan.dart';
import '../../providers/word_provider.dart';
import 'carousel_plan_edit_screen.dart';
import '../../widgets/empty_state.dart';

class CarouselPlayerScreen extends StatefulWidget {
  const CarouselPlayerScreen({super.key});
  @override
  State<CarouselPlayerScreen> createState() => _CarouselPlayerScreenState();
}

class _CarouselPlayerScreenState extends State<CarouselPlayerScreen> {
  VoidCallback? _authListener;
  String? _lastUid;
  @override
  void initState() {
    super.initState();
    // 等待 Auth 就绪后再加载轮播相关数据，避免使用空用户导致不一致
    _authListener = () async {
      final auth = context.read<AuthProvider>();
      if (auth.initializing) return;
      final uid = auth.userId;
      if (_lastUid == uid) return;
      _lastUid = uid;
      // 先加载启用的单词与方案列表
      await context.read<WordProvider>().loadWords(onlyEnabled: true, userId: uid);
      await context.read<CarouselPlanProvider>().load(userId: uid);
      // 加载播放配置与默认队列
      final p = context.read<CarouselProvider>();
      await p.loadConfigFromPrefs();
      await p.buildDeck(onlyEnabled: true, userId: uid);
    };
    context.read<AuthProvider>().addListener(_authListener!);
    WidgetsBinding.instance.addPostFrameCallback((_) => _authListener!.call());
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CarouselProvider>();
    final WordCard? current = provider.playingDeck.isEmpty ? null : provider.playingDeck[provider.currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('轮播播放'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            tooltip: '新建轮播方案',
            onPressed: () async {
              final newId = await Navigator.push<String>(
                context,
                MaterialPageRoute(builder: (_) => const CarouselPlanEditScreen()),
              );
              if (newId != null && newId.isNotEmpty) {
                final auth = context.read<AuthProvider>();
                final uid = auth.userId;
                final planProv = context.read<CarouselPlanProvider>();
                await planProv.load(userId: uid);
                planProv.select(newId);
                final wordProv = context.read<WordProvider>();
                final ids = planProv.selected?.wordIds ?? const [];
                final fetched = await context.read<WordProvider>().findWordsByIds(ids);
                var deck = fetched.where((w) => w.enabled).toList();
                if (provider.cfg.shuffle && deck.isNotEmpty) {
                  deck.shuffle();
                }
                provider.setDeck(deck);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('方案已保存并可播放')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            tooltip: '选择轮播方案',
            onPressed: () => _showPlanSelector(context),
          ),
        ],
      ),
      body: current == null
          ? const EmptyState(message: '没有可播放的卡片\n请先在“单词卡列表”添加或导入词条，并确保已启用')
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Config controls
                  _ConfigBar(provider: provider),
                  const SizedBox(height: 12),
                  // Word content
                  Text(current.word, style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(current.phonetic, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(current.chinese, style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  _Countdown(provider: provider),
                  const SizedBox(height: 12),
                  _Controls(provider: provider),
                ],
              ),
            ),
    );
  }

  @override
  void dispose() {
    if (_authListener != null) {
      context.read<AuthProvider>().removeListener(_authListener!);
    }
    super.dispose();
  }
}

Future<void> _showCreatePlanDialog(BuildContext context) async {
  final targetCtrl = TextEditingController(text: '10');
  final cycleCtrl = TextEditingController(text: '7');
  final timeCtrl = TextEditingController(text: '20:00');
  await showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('新建学习计划'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: targetCtrl, decoration: const InputDecoration(labelText: '每日目标单词数'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: cycleCtrl, decoration: const InputDecoration(labelText: '复习周期（天）'), keyboardType: TextInputType.number),
          const SizedBox(height: 8),
          TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: '提醒时间（HH:mm）')),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        ElevatedButton(
          onPressed: () async {
            final auth = context.read<AuthProvider>();
            final userId = auth.userId;
            if (userId == null) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请先登录后再创建学习计划')));
              return;
            }
            final p = context.read<StudyPlanProvider>();
            final plan = StudyPlan(userId: userId);
            plan.targetWords = int.tryParse(targetCtrl.text) ?? plan.targetWords;
            plan.reviewCycleDays = int.tryParse(cycleCtrl.text) ?? plan.reviewCycleDays;
            plan.reminderTime = timeCtrl.text.trim().isEmpty ? plan.reminderTime : timeCtrl.text.trim();
            await p.save(plan);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已创建学习计划')));
            }
          },
          child: const Text('保存'),
        ),
      ],
    ),
  );
}

Future<void> _showPlanSelector(BuildContext context, {bool initialCreating = false}) async {
  final auth = context.read<AuthProvider>();
  final userId = auth.userId;
  final planProvider = context.read<CarouselPlanProvider>();
  await planProvider.load(userId: userId);
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) {
      return _PlanSelectorSheet(userId: userId, initialCreating: false);
    },
  );
}

class _PlanSelectorSheet extends StatefulWidget {
  final String? userId;
  final bool initialCreating;
  const _PlanSelectorSheet({this.userId, this.initialCreating = false});

  @override
  State<_PlanSelectorSheet> createState() => _PlanSelectorSheetState();
}

class _PlanSelectorSheetState extends State<_PlanSelectorSheet> {
  bool _creating = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final Set<String> _selectedWordIds = {};
  bool _selectingPlans = false;
  final Set<String> _selectedPlanIds = {};

  @override
  void initState() {
    super.initState();
    final words = context.read<WordProvider>();
    if (words.words.isEmpty) {
      words.loadWords(userId: widget.userId);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<CarouselPlanProvider>().plans;
    final wordProv = context.watch<WordProvider>();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: 520,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Text('轮播方案', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.end,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.checklist),
                        label: Text(_selectingPlans ? '退出选择' : '选择'),
                        onPressed: () {
                          setState(() {
                            _selectingPlans = !_selectingPlans;
                            if (!_selectingPlans) _selectedPlanIds.clear();
                          });
                        },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.delete_forever),
                        label: const Text('批量删除'),
                        onPressed: _selectedPlanIds.isEmpty
                            ? null
                            : () async {
                                final ok = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text('确认删除'),
                                        content: Text('将删除选中的 ${_selectedPlanIds.length} 个方案'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
                                        ],
                                      ),
                                    ) ??
                                    false;
                                if (!ok) return;
                                final auth = context.read<AuthProvider>();
                                final uid = auth.userId;
                                for (final id in _selectedPlanIds.toList()) {
                                  await context.read<CarouselPlanProvider>().delete(id, userId: uid);
                                }
                                setState(() {
                                  _selectedPlanIds.clear();
                                  _selectingPlans = false;
                                });
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('已批量删除方案')),
                                  );
                                }
                              },
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('新建方案'),
                        onPressed: () async {
                          Navigator.pop(context);
                          final newId = await Navigator.push<String>(
                            context,
                            MaterialPageRoute(builder: (_) => const CarouselPlanEditScreen()),
                          );
                          if (newId != null && newId.isNotEmpty && context.mounted) {
                            final auth = context.read<AuthProvider>();
                            final uid = auth.userId;
                            final planProv = context.read<CarouselPlanProvider>();
                            await planProv.load(userId: uid);
                            planProv.select(newId);
                            final ids = planProv.selected?.wordIds ?? const [];
                            final fetched = await context.read<WordProvider>().findWordsByIds(ids);
                            final provider = context.read<CarouselProvider>();
                            var deck = fetched.where((w) => w.enabled).toList();
                            provider.setDeck(deck, startPlaying: deck.isNotEmpty);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('方案已保存并就绪')));
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _buildPlanList(plans, wordProv.words),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList(List<CarouselPlan> plans, List<WordCard> words) {
    final provider = context.read<CarouselProvider>();
    return ListView.builder(
      itemCount: plans.length,
      itemBuilder: (_, i) {
        final p = plans[i];
        return ListTile(
          leading: _selectingPlans
              ? Checkbox(
                  value: _selectedPlanIds.contains(p.id),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _selectedPlanIds.add(p.id);
                      } else {
                        _selectedPlanIds.remove(p.id);
                      }
                    });
                  },
                )
              : null,
          title: Text(p.name),
          subtitle: Text('词数: ${p.wordIds.length}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: '播放此方案',
                icon: const Icon(Icons.play_circle_fill),
                onPressed: () async {
                  final fetched = await context.read<WordProvider>().findWordsByIds(p.wordIds);
                  final deck = fetched.where((w) => w.enabled).toList();
                  provider.setDeck(deck, startPlaying: true);
                  Navigator.pop(context);
                },
              ),
              IconButton(
                tooltip: '删除',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('确认删除'),
                          content: Text('删除方案 "${p.name}"'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
                            ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
                          ],
                        ),
                      ) ??
                      false;
                  if (!ok) return;
                  await context.read<CarouselPlanProvider>().delete(p.id, userId: p.userId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 创建已迁移到独立页面，这里仅保留列表与播放/删除。
}

class _ConfigBar extends StatelessWidget {
  final CarouselProvider provider;
  const _ConfigBar({required this.provider});
  @override
  Widget build(BuildContext context) {
    final modes = const ['5min','10min','20min','1h','forever'];
    final planProv = context.watch<CarouselPlanProvider>();
    final wordProv = context.watch<WordProvider>();
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Plan selector
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('方案'),
          const SizedBox(width: 6),
          DropdownButton<String>(
            value: planProv.selected?.id ?? 'none',
            items: [
              const DropdownMenuItem(value: 'none', child: Text('不使用方案')),
              ...planProv.plans.map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
            ],
            onChanged: (v) async {
              if (v == null) return;
              if (v == 'none') {
                planProv.clearSelection();
                final uid = context.read<AuthProvider>().userId;
                await provider.buildDeck(onlyEnabled: true, userId: uid);
              } else {
                planProv.select(v);
                final ids = planProv.selected?.wordIds ?? const [];
                final fetched = await context.read<WordProvider>().findWordsByIds(ids);
                var deck = fetched.where((w) => w.enabled).toList();
                if (provider.cfg.shuffle && deck.isNotEmpty) {
                  deck.shuffle();
                }
                provider.setDeck(deck);
              }
            },
          ),
        ]),
        const SizedBox(width: 16),
        // Duration mode selector
        DropdownButton<String>(
          value: provider.cfg.durationMode,
          items: modes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (v) {
            if (v == null) return;
            provider.applyConfig(CarouselConfig(
              shuffle: provider.cfg.shuffle,
              intervalSeconds: provider.cfg.intervalSeconds,
              showRelated: provider.cfg.showRelated,
              selectedTagIds: provider.cfg.selectedTagIds,
              voice: provider.cfg.voice,
              autoPlaySound: provider.cfg.autoPlaySound,
              durationMode: v,
              loopForever: v == 'forever',
            ));
          },
        ),
        const SizedBox(width: 16),
        // Interval stepper
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('间隔'),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              final next = (provider.cfg.intervalSeconds - 1).clamp(1, 60);
              provider.applyConfig(CarouselConfig(
                shuffle: provider.cfg.shuffle,
                intervalSeconds: next,
                showRelated: provider.cfg.showRelated,
                selectedTagIds: provider.cfg.selectedTagIds,
                voice: provider.cfg.voice,
                autoPlaySound: provider.cfg.autoPlaySound,
                durationMode: provider.cfg.durationMode,
                loopForever: provider.cfg.loopForever,
              ));
            },
          ),
          Text('${provider.cfg.intervalSeconds}s'),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final next = (provider.cfg.intervalSeconds + 1).clamp(1, 60);
              provider.applyConfig(CarouselConfig(
                shuffle: provider.cfg.shuffle,
                intervalSeconds: next,
                showRelated: provider.cfg.showRelated,
                selectedTagIds: provider.cfg.selectedTagIds,
                voice: provider.cfg.voice,
                autoPlaySound: provider.cfg.autoPlaySound,
                durationMode: provider.cfg.durationMode,
                loopForever: provider.cfg.loopForever,
              ));
            },
          ),
        ]),
        const SizedBox(width: 16),
        // Auto play toggle
        Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('自动发音'),
          Switch(
            value: provider.cfg.autoPlaySound,
            onChanged: (v) {
              provider.applyConfig(CarouselConfig(
                shuffle: provider.cfg.shuffle,
                intervalSeconds: provider.cfg.intervalSeconds,
                showRelated: provider.cfg.showRelated,
                selectedTagIds: provider.cfg.selectedTagIds,
                voice: provider.cfg.voice,
                autoPlaySound: v,
                durationMode: provider.cfg.durationMode,
                loopForever: provider.cfg.loopForever,
              ));
            },
          ),
        ]),
      ],
    );
  }
}

class _Countdown extends StatelessWidget {
  final CarouselProvider provider;
  const _Countdown({required this.provider});
  @override
  Widget build(BuildContext context) {
    final rem = provider.remaining();
    if (rem == null) return const SizedBox.shrink();
    final mm = rem.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = rem.inSeconds.remainder(60).toString().padLeft(2, '0');
    return Text('剩余: $mm:$ss', style: Theme.of(context).textTheme.titleMedium);
  }
}

class _Controls extends StatelessWidget {
  final CarouselProvider provider;
  const _Controls({required this.provider});
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(onPressed: provider.prev, icon: const Icon(Icons.skip_previous)),
        IconButton(
          onPressed: provider.isPlaying ? provider.pause : provider.start,
          icon: Icon(provider.isPlaying ? Icons.pause_circle : Icons.play_circle),
          iconSize: 48,
        ),
        IconButton(onPressed: provider.next, icon: const Icon(Icons.skip_next)),
      ],
    );
  }
}