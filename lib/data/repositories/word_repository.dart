import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../dao/word_card_dao.dart';
import '../dao/tag_dao.dart';
import '../models/word_card.dart';
import '../models/tag.dart';
import '../db.dart';

class WordRepository {
  final _dao = WordCardDAO();
  final _tagDao = TagDAO();
  final _uuid = const Uuid();

  Future<List<WordCard>> list({List<String>? tagIds, bool? onlyEnabled}) async {
    final words = await _dao.list(tagIds: tagIds, onlyEnabled: onlyEnabled);
    // hydrate tagIds
    for (final w in words) {
      final tags = await _tagDao.listByWord(w.id);
      w.tagIds = tags.map((e) => e.id).toList();
    }
    return words;
  }

  Future<void> create(WordCard w) async {
    await _dao.insertWord(w);
    await _tagDao.setTagsForWord(w.id, w.tagIds);
  }

  Future<void> update(WordCard w) async {
    await _dao.updateWord(w);
    await _tagDao.setTagsForWord(w.id, w.tagIds);
  }

  Future<void> delete(String id) async {
    await _dao.deleteWord(id);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final w = await _dao.findById(id);
    if (w == null) return;
    w.enabled = enabled;
    await _dao.updateWord(w);
  }

  // Simple list import/export (legacy)
  Future<int> importFromJsonString(String jsonStr) async {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    int count = 0;
    for (final item in list) {
      final j = Map<String, dynamic>.from(item);
      final id = j['id'] ?? _uuid.v4();
      final w = WordCard.fromJson({...j, 'id': id});
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

    final db = await AppDatabase.instance.database;
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
}