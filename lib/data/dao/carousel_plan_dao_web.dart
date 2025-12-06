import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/carousel_plan.dart';

class CarouselPlanDAOWeb {
  static const _key = 'ewc_carousel_plans_v1';

  Future<List<CarouselPlan>> listAll({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = (jsonDecode(raw) as List<dynamic>).map((e) => CarouselPlan.fromJson(Map<String, dynamic>.from(e))).toList();
    if (userId == null) return list;
    return list.where((p) => p.userId == null || p.userId == userId).toList();
  }

  Future<void> upsert(CarouselPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await listAll(userId: null);
    final idx = list.indexWhere((p) => p.id == plan.id);
    if (idx >= 0) {
      list[idx] = plan;
    } else {
      list.insert(0, plan);
    }
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }

  Future<void> delete(String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await listAll(userId: null);
    list.removeWhere((p) => p.id == planId);
    final jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await prefs.setString(_key, jsonStr);
  }
}