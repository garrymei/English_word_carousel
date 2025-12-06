import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../data/models/word_card.dart';
import 'supabase_service.dart';

class WordCardsSupabaseService {
  static Future<List<WordCard>> fetchAll({int limit = 100, bool? onlyEnabled, String? userId, bool personalOnly = true}) async {
    if (!SupabaseService.isInitialized) return [];
    final client = SupabaseService.client;
    var query = client.from('word_cards').select();

    if (onlyEnabled == true) {
      query = query.eq('enabled', true);
    }
    // Scope: personal only
    if (userId != null && userId.isNotEmpty) {
      query = query.eq('user_id', userId);
    } else {
      // No user -> show nothing for personal scope
      return [];
    }
    print('Fetching words with userId: $userId, onlyEnabled: $onlyEnabled, personalOnly: true');
    final rows = await query.order('created_at', ascending: false).limit(limit);
    print('Fetched ${rows.length} rows from Supabase');
    return _mapRows(rows);
  }

  static Future<List<WordCard>> fetchByIds(List<String> ids) async {
    if (!SupabaseService.isInitialized) return [];
    final client = SupabaseService.client;
    if (ids.isEmpty) return [];
    final orExpr = ids.map((e) => 'id.eq.$e').join(',');
    final rows = await client
        .from('word_cards')
        .select()
        .or(orExpr)
        .order('updated_at', ascending: false);
    return _mapRows(rows);
  }

  /// Insert a word card into Supabase and return the inserted row mapped to WordCard.
  /// Requires RLS to allow insert for current user (or anon during testing).
  static Future<WordCard?> createRemote(WordCard w) async {
    if (!SupabaseService.isInitialized) return null;
    final client = SupabaseService.client;

    // Prefer explicit user id from payload; otherwise use current auth user.
    final currentUserId = w.userId ?? client.auth.currentUser?.id;
    final payload = {
      'word': w.word,
      'chinese': w.chinese,
      'phonetic': w.phonetic,
      'phrase': w.phrase,
      'phrase_cn': w.phraseCn,
      'sentence_en': w.sentenceEn,
      'sentence_cn': w.sentenceCn,
      'related_enabled': w.relatedEnabled,
      'related': w.related.map((e) => e.toJson()).toList(),
      'enabled': w.enabled,
      'audio_us': w.audioPathUs,
      'audio_uk': w.audioPathUk,
      'user_id': currentUserId,
    };
    // Remove nulls to avoid overwriting defaults/triggers
    payload.removeWhere((key, value) => value == null);

    final rows = await client
        .from('word_cards')
        .insert(payload)
        .select(
            'id, word, chinese, phonetic, phrase, phrase_cn, sentence_en, sentence_cn, related, related_enabled, enabled, audio_us, audio_uk, user_id, created_at, updated_at')
        .limit(1);

    final list = _mapRows(rows);
    return list.isNotEmpty ? list.first : null;
  }

  static List<WordCard> _mapRows(dynamic rows) {
    if (rows is! List) return [];
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r as Map);
      DateTime _parseTime(dynamic v) {
        if (v == null) return DateTime.now();
        if (v is int) {
          // milliseconds epoch
          return DateTime.fromMillisecondsSinceEpoch(v);
        }
        if (v is String) {
          try {
            return DateTime.parse(v);
          } catch (_) {
            return DateTime.now();
          }
        }
        return DateTime.now();
      }

      List<Map<String, dynamic>> _parseRelated(dynamic relatedRaw) {
        if (relatedRaw == null) return const [];
        if (relatedRaw is List) {
          final out = <Map<String, dynamic>>[];
          for (final e in relatedRaw) {
            if (e is Map) {
              out.add(Map<String, dynamic>.from(e));
            } else if (e is String) {
              try {
                final decoded = json.decode(e);
                if (decoded is Map) {
                  out.add(Map<String, dynamic>.from(decoded));
                }
              } catch (_) {}
            }
          }
          return out;
        }
        if (relatedRaw is String) {
          try {
            final decoded = json.decode(relatedRaw);
            if (decoded is List) {
              return decoded
                  .whereType<Map>()
                  .map((e) => Map<String, dynamic>.from(e))
                  .toList();
            }
            if (decoded is Map) {
              return [Map<String, dynamic>.from(decoded)];
            }
          } catch (_) {}
        }
        return const [];
      }
      final relatedList = _parseRelated(m['related']);

      return WordCard(
        id: (m['id']?.toString() ?? ''),
        word: (m['word']?.toString() ?? m['term']?.toString() ?? ''),
        chinese: (m['chinese']?.toString() ?? m['definition']?.toString() ?? ''),
        phonetic: (m['phonetic']?.toString() ?? ''),
        phrase: (m['phrase']?.toString() ?? ''),
        phraseCn: (m['phrase_cn']?.toString() ?? ''),
        sentenceEn: (m['sentence_en']?.toString() ?? ''),
        sentenceCn: (m['sentence_cn']?.toString() ?? ''),
        relatedEnabled: (m['related_enabled'] == true),
        related: relatedList.map((e) => RelatedWord.fromJson(e)).toList(),
        enabled: (m['enabled'] == null ? true : (m['enabled'] == true)),
        tagIds: const [],
        createdAt: _parseTime(m['created_at']),
        updatedAt: _parseTime(m['updated_at']),
        audioPathUs: m['audio_us'] as String?,
        audioPathUk: m['audio_uk'] as String?,
        userId: m['user_id'] as String?,
      );
    }).toList();
  }
}