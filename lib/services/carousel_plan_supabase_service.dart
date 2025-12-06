import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/carousel_plan.dart';
import 'supabase_service.dart';

class CarouselPlanSupabaseService {
  static Future<List<CarouselPlan>> listAll({String? userId}) async {
    if (!SupabaseService.isInitialized) return [];
    final client = SupabaseService.client;
    final base = client.from('carousel_plans').select();
    final rows = userId != null && userId.isNotEmpty
        ? await base.eq('user_id', userId).order('updated_at', ascending: false)
        : await base.order('updated_at', ascending: false);
ListTile(
  title: const Text('轮播方案'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
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
      const SizedBox(width: 8),
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
                    ) ?? false;
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
              },
      ),
      const SizedBox(width: 8),
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
),ListTile(
  title: const Text('轮播方案'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
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
      const SizedBox(width: 8),
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
                    ) ?? false;
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
              },
      ),
      const SizedBox(width: 8),
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
),ListTile(
  title: const Text('轮播方案'),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
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
      const SizedBox(width: 8),
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
                    ) ?? false;
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
              },
      ),
      const SizedBox(width: 8),
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
),    debugPrint('CarouselPlanSupabaseService: listAll rows=${(rows as List).length} userId=$userId');
    final plans = <CarouselPlan>[];
    final planIds = <String>[];
    for (final r in (rows as List)) {
      final m = Map<String, dynamic>.from(r as Map);
      final p = CarouselPlan(
        id: (m['id']?.toString() ?? ''),
        name: (m['name']?.toString() ?? ''),
        userId: m['user_id'] as String?,
        createdAt: _parseTime(m['created_at']),
        updatedAt: _parseTime(m['updated_at']),
      );
      if (p.id.isNotEmpty) {
        plans.add(p);
        planIds.add(p.id);
      }
    }
    if (planIds.isNotEmpty) {
      final orExpr = planIds.map((e) => 'plan_id.eq.$e').join(',');
      final relRows = await client.from('carousel_plan_words').select().or(orExpr).order('plan_id');
      debugPrint('CarouselPlanSupabaseService: rel rows=${(relRows as List).length}');
      final byPlan = <String, List<String>>{};
      for (final r in (relRows as List)) {
        final m = Map<String, dynamic>.from(r as Map);
        final pid = (m['plan_id']?.toString() ?? '');
        final wid = (m['word_id']?.toString() ?? '');
        if (pid.isEmpty || wid.isEmpty) continue;
        byPlan.putIfAbsent(pid, () => <String>[]).add(wid);
      }
      for (final p in plans) {
        p.wordIds = byPlan[p.id] ?? const [];
      }
    }
    return plans;
  }

  static Future<void> upsert(CarouselPlan plan) async {
    if (!SupabaseService.isInitialized) return;
    final client = SupabaseService.client;
    final payload = {
      'id': plan.id,
      'name': plan.name,
      'user_id': plan.userId,
      'created_at': plan.createdAt.toIso8601String(),
      'updated_at': plan.updatedAt.toIso8601String(),
    }..removeWhere((k, v) => v == null);
    await client.from('carousel_plans').upsert(payload);
    await setWords(plan.id, plan.wordIds);
  }

  static Future<void> delete(String planId) async {
    if (!SupabaseService.isInitialized) return;
    final client = SupabaseService.client;
    await client.from('carousel_plan_words').delete().eq('plan_id', planId);
    await client.from('carousel_plans').delete().eq('id', planId);
  }

  static Future<List<String>> getWords(String planId) async {
    if (!SupabaseService.isInitialized) return [];
    final client = SupabaseService.client;
    final rows = await client.from('carousel_plan_words').select().eq('plan_id', planId);
    return (rows as List)
        .map((e) => (Map<String, dynamic>.from(e)['word_id']?.toString() ?? ''))
        .where((id) => id.isNotEmpty)
        .toList();
  }

  static Future<void> setWords(String planId, List<String> wordIds) async {
    if (!SupabaseService.isInitialized) return;
    final client = SupabaseService.client;
    await client.from('carousel_plan_words').delete().eq('plan_id', planId);
    if (wordIds.isEmpty) return;
    final payload = wordIds.toSet().map((id) => {'plan_id': planId, 'word_id': id}).toList();
    await client.from('carousel_plan_words').insert(payload);
  }

  static DateTime _parseTime(dynamic v) {
    if (v == null) return DateTime.now();
    if (v is String) {
      try {
        return DateTime.parse(v);
      } catch (_) {
        return DateTime.now();
      }
    }
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    return DateTime.now();
  }
}