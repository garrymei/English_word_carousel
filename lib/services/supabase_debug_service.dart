import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class SupabaseDebugService {
  /// Insert a smoke-test row into `ewc_test` and print the inserted id.
  /// Requires a table `ewc_test(id uuid default gen_random_uuid() primary key, note text, created_at timestamptz default now())`
  /// and permissive RLS for anon: select/insert allowed.
  static Future<void> runSmokeTest() async {
    if (!SupabaseService.isInitialized) {
      debugPrint('Supabase smoke test skipped: service not initialized');
      return;
    }
    final client = SupabaseService.client;
    try {
      final note = 'EWC smoke test @ ${DateTime.now().toIso8601String()}';
      final rows = await client
          .from('ewc_test')
          .insert({'note': note})
          .select()
          .limit(1);
      if (rows is List && rows.isNotEmpty) {
        final id = rows.first['id'];
        debugPrint('Supabase smoke test success: id=$id, note=$note');
      } else {
        debugPrint('Supabase smoke test inserted but no row returned');
      }
    } catch (e) {
      debugPrint('Supabase smoke test error: $e');
    }
  }

  /// Insert a demo word card into `word_cards` and print the inserted id/term.
  /// Requires a table `word_cards(id uuid default gen_random_uuid() primary key, term text, definition text, tags text[], source text default 'EWC', created_at timestamptz default now())`
  /// and permissive RLS for anon: select/insert allowed (for testing only).
  static Future<void> runWordCardDemo() async {
    if (!SupabaseService.isInitialized) {
      debugPrint('Supabase word card demo skipped: service not initialized');
      return;
    }
    final client = SupabaseService.client;
    try {
      final nowIso = DateTime.now().toIso8601String();
      final payload = {
        'word': 'serendipity',
        'chinese': '意外的幸运；机缘巧合产生的美好结果',
        'tags': ['demo', 'ewc'],
        'source': 'EWC',
        'created_at': nowIso,
      };
      final rows = await client
          .from('word_cards')
          .insert(payload)
          .select()
          .limit(1);
      if (rows is List && rows.isNotEmpty) {
        final id = rows.first['id'];
        final term = rows.first['word'] ?? rows.first['term'];
        debugPrint('Supabase word card demo success: id=$id, word=$term');
      } else {
        debugPrint('Supabase word card demo inserted but no row returned');
      }
    } catch (e) {
      debugPrint('Supabase word card demo error: $e');
    }
  }
}