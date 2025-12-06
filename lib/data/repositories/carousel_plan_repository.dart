import 'package:flutter/foundation.dart';
import '../models/carousel_plan.dart';
import '../dao/carousel_plan_dao.dart';
import '../dao/carousel_plan_dao_web.dart';
import '../../services/carousel_plan_supabase_service.dart';
import '../../services/supabase_service.dart';

class CarouselPlanRepository {
  final CarouselPlanDAO? _dao = kIsWeb ? null : CarouselPlanDAO();
  final CarouselPlanDAOWeb? _web = kIsWeb ? CarouselPlanDAOWeb() : null;

  Future<List<CarouselPlan>> listAll({String? userId}) async {
    const readRemote = bool.fromEnvironment('SUPABASE_READ_REMOTE_PLANS', defaultValue: true);
    if (readRemote && SupabaseService.isInitialized) {
      final remote = await CarouselPlanSupabaseService.listAll(userId: userId);
      debugPrint('CarouselPlanRepository: remote plans fetched=${remote.length} for userId=$userId');
      if (remote.isNotEmpty) return remote;
    }
    if (kIsWeb) {
      final web = _web;
      if (web == null) return [];
      return web.listAll(userId: userId);
    }
    final dao = _dao;
    if (dao == null) return [];
    final plans = await dao.listAll(userId: userId);
    // Hydrate wordIds for native (stored in association table)
    for (final p in plans) {
      p.wordIds = await dao.getWords(p.id);
    }
    return plans;
  }

  Future<void> upsert(CarouselPlan plan) async {
    const writeRemote = bool.fromEnvironment('SUPABASE_WRITE_REMOTE_PLANS', defaultValue: true);
    if (writeRemote && SupabaseService.isInitialized) {
      await CarouselPlanSupabaseService.upsert(plan);
      debugPrint('CarouselPlanRepository: remote upsert id=${plan.id} name=${plan.name}');
    }
    if (kIsWeb) {
      final web = _web;
      if (web == null) return;
      await web.upsert(plan);
    } else {
      final dao = _dao;
      if (dao == null) return;
      await dao.upsert(plan);
      debugPrint('CarouselPlanRepository: local upsert id=${plan.id} name=${plan.name}');
    }
  }

  Future<void> delete(String planId) async {
    const writeRemote = bool.fromEnvironment('SUPABASE_WRITE_REMOTE_PLANS', defaultValue: true);
    if (writeRemote && SupabaseService.isInitialized) {
      await CarouselPlanSupabaseService.delete(planId);
    }
    if (kIsWeb) {
      final web = _web;
      if (web == null) return;
      await web.delete(planId);
    } else {
      final dao = _dao;
      if (dao == null) return;
      await dao.delete(planId);
    }
  }

  Future<List<String>> getWordIds(String planId) async {
    const readRemote = bool.fromEnvironment('SUPABASE_READ_REMOTE_PLANS', defaultValue: true);
    if (readRemote && SupabaseService.isInitialized) {
      return CarouselPlanSupabaseService.getWords(planId);
    }
    if (kIsWeb) {
      final web = _web;
      if (web == null) return [];
      final plans = await web.listAll(userId: null);
      final p = plans.firstWhere((e) => e.id == planId, orElse: () => CarouselPlan(id: '', name: '')); // empty fallback
      return p.wordIds;
    } else {
      final dao = _dao;
      if (dao == null) return [];
      return dao.getWords(planId);
    }
  }
}
