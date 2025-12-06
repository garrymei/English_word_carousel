import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../dao/word_card_dao.dart';
import '../dao/word_card_dao_sqflite.dart';
import '../dao/word_card_dao_web.dart';
import '../dao/tag_dao.dart';
import '../models/word_card.dart';
import '../models/tag.dart';
import '../db.dart';

class WordRepository {
  final WordCardDAO _dao = kIsWeb ? WordCardDAOWeb() : WordCardDAOSqflite();
  final _tagDao = TagDAO();
  final _uuid = const Uuid();

  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled, String? userId, bool personalOnly = false}) async {
    final words = await _dao.list(tagIds: tagIds, onlyEnabled: onlyEnabled, userId: userId, personalOnly: personalOnly);
    if (!kIsWeb) {
      // hydrate tagIds from link table on native platforms
      for (final w in words) {
        final tags = await _tagDao.listByWord(w.id);
        w.tagIds = tags.map((e) => e.id).toList();
      }
    }
    return words;
  }

  Future<void> create(WordCard w) async {
    await _dao.insertWord(w);
    // 在 Web 环境下不使用本地 DB 的标签关联，避免抛错导致回退到内存
    if (!kIsWeb) {
      await _tagDao.setTagsForWord(w.id, w.tagIds);
    }
  }

  Future<void> update(WordCard w) async {
    await _dao.updateWord(w);
    if (!kIsWeb) {
      await _tagDao.setTagsForWord(w.id, w.tagIds);
    }
  }

  Future<void> delete(String id) async {
    await _dao.deleteWord(id);
  }

  Future<void> deleteMany(List<String> ids) async {
    await _dao.deleteWordsByIds(ids);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final w = await _dao.findById(id);
    if (w == null) return;
    w.enabled = enabled;
    await _dao.updateWord(w);
  }

  Future<List<WordCard>> findByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final results = <WordCard>[];
    for (final id in ids) {
      final w = await _dao.findById(id);
      if (w != null) {
        if (!kIsWeb) {
          final tags = await _tagDao.listByWord(w.id);
          w.tagIds = tags.map((e) => e.id).toList();
        }
        results.add(w);
      }
    }
    // Sort by updatedAt desc to align with list()
    results.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return results;
  }

  // Simple list import/export (legacy)
  Future<int> importFromJsonString(String jsonStr) async {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    int count = 0;
    for (final item in list) {
      final j = Map<String, dynamic>.from(item);
      final id = (j['id'] ?? _uuid.v4()).toString();
      // Ensure tagIds exist to avoid FK violations
      final rawTagIds = (j['tag_ids'] as List? ?? []).map((e) => e.toString()).toSet().toList();
      final validTagIds = <String>[];
      for (final tid in rawTagIds) {
        final exists = await _tagDao.findById(tid) != null;
        if (exists) validTagIds.add(tid);
      }
      final w = WordCard.fromJson({...j, 'id': id});
      w.tagIds = validTagIds;
      await create(w);
      count++;
    }
    return count;
  }

  Future<String> exportToJsonString(List<WordCard> words) async {
    return jsonEncode(words.map((e) => e.toJson()).toList());
  }

  // Versioned export: include tags and words
  Future<String> exportBundle() async {
    final tags = await _tagDao.listAll();
    final words = await list();
    final bundle = {
      'version': '1.0',
      'exported_at': DateTime.now().toUtc().toIso8601String(),
      'tags': tags.map((t) => t.toJson()).toList(),
      'words': words.map((w) => w.toJson()).toList(),
    };
    return jsonEncode(bundle);
  }

  // Import bundle with transaction and validation
  Future<int> importBundle(String jsonStr, {int chunkSize = 500}) async {
    final obj = jsonDecode(jsonStr);
    if (obj is! Map) throw FormatException('Invalid JSON root, expected object');

    final tagsJson = List<Map<String, dynamic>>.from(obj['tags'] as List? ?? const []);
    final wordsJson = List<Map<String, dynamic>>.from(obj['words'] as List? ?? const []);

    // pre-validate
    for (final wj in wordsJson) {
      if ((wj['word'] ?? '').toString().trim().isEmpty) {
        throw FormatException('WordCard.word is required');
      }
      if ((wj['chinese'] ?? '').toString().trim().isEmpty) {
        throw FormatException('WordCard.chinese is required');
      }
    }

    // validate tag references against provided tags and DB
    final referencedTagIds = <String>{};
    for (final wj in wordsJson) {
      final ids = (wj['tag_ids'] as List? ?? []).map((e) => e.toString());
      referencedTagIds.addAll(ids);
    }
    final providedTagIds = tagsJson.map((tj) => (tj['id']).toString()).toSet();

    final missingCandidates = referencedTagIds.difference(providedTagIds);
    final db = await AppDatabase.instance.database;
    if (missingCandidates.isNotEmpty) {
      final placeholders = List.filled(missingCandidates.length, '?').join(',');
      final rows = await db.query(
        'tags',
        columns: ['id'],
        where: 'id IN ($placeholders)',
        whereArgs: missingCandidates.toList(),
      );
      final existingIds = rows.map((r) => (r['id'] as String)).toSet();
      final unknown = missingCandidates.difference(existingIds);
      if (unknown.isNotEmpty) {
        throw FormatException('Unknown tag_ids referenced: ${unknown.join(', ')}');
      }
    }
    int imported = 0;

    // If very large, paginate multiple transactions to avoid giant TX
    if (wordsJson.length > chunkSize) {
      // Upsert tags first in one TX
      await db.transaction((txn) async {
        for (final tj in tagsJson) {
          final tag = Tag.fromJson(Map<String, dynamic>.from(tj));
          final rows = await txn.query('tags', where: 'id = ?', whereArgs: [tag.id]);
          if (rows.isEmpty) {
            await txn.insert('tags', tag.toDbMap());
          } else {
            await txn.update('tags', tag.toDbMap(), where: 'id = ?', whereArgs: [tag.id]);
          }
        }
      });

      for (int i = 0; i < wordsJson.length; i += chunkSize) {
        final chunk = wordsJson.sublist(i, i + chunkSize > wordsJson.length ? wordsJson.length : i + chunkSize);
        await db.transaction((txn) async {
          for (final wj in chunk) {
            final id = (wj['id'] ?? _uuid.v4()).toString();
            final w = WordCard.fromJson({...wj, 'id': id});
            // upsert word
            final rows = await txn.query('word_cards', where: 'id = ?', whereArgs: [w.id]);
            if (rows.isEmpty) {
              await txn.insert('word_cards', w.toDbMap());
            } else {
              await txn.update('word_cards', w.toDbMap(), where: 'id = ?', whereArgs: [w.id]);
            }
            // set tags
            final tagIds = (wj['tag_ids'] as List? ?? []).map((e) => e.toString()).toList();
            await txn.delete('word_card_tags', where: 'word_id = ?', whereArgs: [w.id]);
            for (final tid in tagIds) {
              await txn.insert('word_card_tags', {'word_id': w.id, 'tag_id': tid});
            }
            imported++;
          }
        });
      }
    } else {
      // Single transaction for all writes
      await db.transaction((txn) async {
        // upsert tags
        for (final tj in tagsJson) {
          final tag = Tag.fromJson(Map<String, dynamic>.from(tj));
          final rows = await txn.query('tags', where: 'id = ?', whereArgs: [tag.id]);
          if (rows.isEmpty) {
            await txn.insert('tags', tag.toDbMap());
          } else {
            await txn.update('tags', tag.toDbMap(), where: 'id = ?', whereArgs: [tag.id]);
          }
        }
        // upsert words
        for (final wj in wordsJson) {
          final id = (wj['id'] ?? _uuid.v4()).toString();
          final w = WordCard.fromJson({...wj, 'id': id});
          final rows = await txn.query('word_cards', where: 'id = ?', whereArgs: [w.id]);
          if (rows.isEmpty) {
            await txn.insert('word_cards', w.toDbMap());
          } else {
            await txn.update('word_cards', w.toDbMap(), where: 'id = ?', whereArgs: [w.id]);
          }
          // set tags
          final tagIds = (wj['tag_ids'] as List? ?? []).map((e) => e.toString()).toList();
          await txn.delete('word_card_tags', where: 'word_id = ?', whereArgs: [w.id]);
          for (final tid in tagIds) {
            await txn.insert('word_card_tags', {'word_id': w.id, 'tag_id': tid});
          }
          imported++;
        }
      });
    }
    return imported;
  }

  // ---- Sync helpers ----
  Future<List<Map<String, dynamic>>> localChanges({DateTime? since}) async {
    final db = await AppDatabase.instance.database;
    final changes = <Map<String, dynamic>>[];
    if (since != null) {
      final wRows = await db.query('word_cards', where: 'updated_at > ?', whereArgs: [since.millisecondsSinceEpoch]);
      final tRows = await db.query('tags', where: 'created_at > ?', whereArgs: [since.millisecondsSinceEpoch]);
      for (final r in wRows) {
        changes.add({'entity': 'word_card', 'action': 'update', 'data': r});
      }
      for (final r in tRows) {
        changes.add({'entity': 'tag', 'action': 'update', 'data': r});
      }
    } else {
      final wRows = await db.query('word_cards');
      final tRows = await db.query('tags');
      for (final r in wRows) {
        changes.add({'entity': 'word_card', 'action': 'update', 'data': r});
      }
      for (final r in tRows) {
        changes.add({'entity': 'tag', 'action': 'update', 'data': r});
      }
    }
    return changes;
  }

  Future<void> applyRemote(Map<String, dynamic> remote) async {
    final db = await AppDatabase.instance.database;
    final tagsJson = List<Map<String, dynamic>>.from(remote['tags'] as List? ?? const []);
    final wordsJson = List<Map<String, dynamic>>.from(remote['words'] as List? ?? const []);

    await db.transaction((txn) async {
      for (final tj in tagsJson) {
        final tag = Tag.fromJson(Map<String, dynamic>.from(tj));
        final rows = await txn.query('tags', where: 'id = ?', whereArgs: [tag.id]);
        if (rows.isEmpty) {
          await txn.insert('tags', tag.toDbMap());
        } else {
          await txn.update('tags', tag.toDbMap(), where: 'id = ?', whereArgs: [tag.id]);
        }
      }
      for (final wj in wordsJson) {
        final id = (wj['id'] ?? _uuid.v4()).toString();
        final w = WordCard.fromJson({...wj, 'id': id});
        final rows = await txn.query('word_cards', where: 'id = ?', whereArgs: [w.id]);
        if (rows.isEmpty) {
          await txn.insert('word_cards', w.toDbMap());
        } else {
          await txn.update('word_cards', w.toDbMap(), where: 'id = ?', whereArgs: [w.id]);
        }
        final tagIds = (wj['tag_ids'] as List? ?? []).map((e) => e.toString()).toList();
        await txn.delete('word_card_tags', where: 'word_id = ?', whereArgs: [w.id]);
        for (final tid in tagIds) {
          await txn.insert('word_card_tags', {'word_id': w.id, 'tag_id': tid});
        }
      }
    });
  }
}