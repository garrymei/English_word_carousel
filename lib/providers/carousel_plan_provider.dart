import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../data/models/carousel_plan.dart';
import '../data/repositories/carousel_plan_repository.dart';

class CarouselPlanProvider extends ChangeNotifier {
  final _repo = CarouselPlanRepository();
  final _uuid = const Uuid();
  List<CarouselPlan> plans = [];
  CarouselPlan? selected;

  Future<void> load({String? userId}) async {
    plans = await _repo.listAll(userId: userId);
    if (selected != null && !plans.any((p) => p.id == selected!.id)) {
      selected = null;
    }
    notifyListeners();
  }

  Future<String> create(String name, {String? userId, List<String> wordIds = const []}) async {
    final p = CarouselPlan(id: _uuid.v4(), name: name, userId: userId, wordIds: wordIds);
    await _repo.upsert(p);
    await load(userId: userId);
    return p.id;
  }

  Future<void> update(CarouselPlan plan) async {
    plan.updatedAt = DateTime.now();
    await _repo.upsert(plan);
    await load(userId: plan.userId);
  }

  Future<void> delete(String planId, {String? userId}) async {
    await _repo.delete(planId);
    await load(userId: userId);
  }

  void select(String planId) {
    final idx = plans.indexWhere((p) => p.id == planId);
    if (idx >= 0) {
      selected = plans[idx];
      notifyListeners();
    }
  }

  void clearSelection() {
    selected = null;
    notifyListeners();
  }
}