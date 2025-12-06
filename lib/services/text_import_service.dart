import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../services/supabase_service.dart';
import '../services/word_cards_supabase_service.dart';
import '../data/models/word_card.dart';
import '../data/repositories/word_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../data/models/tag.dart';

class TextImportResult {
  final int importedCount;
  final List<String> errors;
  TextImportResult({required this.importedCount, required this.errors});
}

class TextImportService {
  final _uuid = const Uuid();
  final WordRepository _wordRepo = WordRepository();
  final TagRepository _tagRepo = TagRepository();

  Uint8List buildTemplateBytes() {
    const sample = '# JSON Lines 文本模板 (UTF-8)\n'
        '# 每行一个 JSON 对象；支持注释行以 # 开头\n'
        '{"word":"abandon","chinese":"放弃","phonetic":"əˈbændən","phrase":"abandon hope","sentence_en":"They abandoned the project.","sentence_cn":"他们放弃了这个项目。","enabled":true,"tags":"核心词,动词","related":[{"text":"desert","chinese":"遗弃"},{"text":"quit","chinese":"退出"}]}\n'
        '{"word":"ability","chinese":"能力","enabled":"是","visibility":"public"}\n';
    return Uint8List.fromList(utf8.encode(sample));
  }

  Future<TextImportResult> importFromBytes(Uint8List bytes, {String? userId}) async {
    final content = utf8.decode(bytes, allowMalformed: true);
    return importFromString(content, userId: userId);
  }

  Future<TextImportResult> importFromString(String content, {String? userId}) async {
    int imported = 0;
    final errors = <String>[];
    // 读取构建期开关：当开启且 Supabase 已初始化时，导入直接写入云端
    const writeRemote = bool.fromEnvironment('SUPABASE_WRITE_REMOTE', defaultValue: true);

    // Build tag name map for current user
    final existingTags = await _tagRepo.listAll(userId: userId);
    final tagNameMap = <String, dynamic>{
      for (final t in existingTags) t.name.trim(): t,
    };

    // Existing words for upsert by word+user
    final existingWords = await _wordRepo.list(userId: userId);

    String _stripBom(String s) => s.replaceFirst(RegExp(r'^\ufeff'), '');
    String _stripBlockTrailingCommas(String s) {
      // Remove trailing commas before closing ] or }
      s = s.replaceAll(RegExp(r',\s*\]'), ']');
      s = s.replaceAll(RegExp(r',\s*\}'), '}');
      return s;
    }
    String _removeCommentLines(String s) {
      final lines = s.split(RegExp(r'\r?\n'));
      final kept = <String>[];
      for (var line in lines) {
        var l = line;
        // remove inline // comments
        l = l.replaceFirst(RegExp(r'//.*$'), '').trimRight();
        if (l.trim().isEmpty) continue;
        if (l.trim().startsWith('#')) continue;
        kept.add(l);
      }
      return kept.join('\n');
    }

    String normalized = _stripBom(content);
    normalized = _removeCommentLines(normalized);
    normalized = _stripBlockTrailingCommas(normalized);

    // Prefer parsing entire content as JSON (array or bundle), fallback to NDJSON lines
    final items = <Map<String, dynamic>>[];
    bool parsedAsPackage = false;
    final trimmed = normalized.trim();
    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is List) {
        for (final e in decoded) {
          if (e is Map) {
            items.add(Map<String, dynamic>.from(e));
          } else {
            errors.add('数组项不是对象，已跳过');
          }
        }
        parsedAsPackage = true;
      } else if (decoded is Map) {
        // Support bundle object with key 'words'
        final words = decoded['words'];
        if (words is List) {
          for (final e in words) {
            if (e is Map) {
              items.add(Map<String, dynamic>.from(e));
            } else {
              errors.add('words 数组项不是对象，已跳过');
            }
          }
          parsedAsPackage = true;
        }
      }
    } catch (_) {
      // ignore — will fallback to line-based
    }

    // If not parsed, attempt to wrap comma-separated objects into JSON array
    if (!parsedAsPackage) {
      final looksLikeCommaSeparatedObjects =
          !trimmed.startsWith('[') && RegExp(r'\}\s*,\s*\{').hasMatch(trimmed);
      if (looksLikeCommaSeparatedObjects) {
        var candidate = trimmed;
        candidate = _removeCommentLines(candidate);
        candidate = _stripBlockTrailingCommas(candidate);
        // Ensure no trailing comma at end
        candidate = candidate.replaceFirst(RegExp(r',\s*$'), '');
        final wrapped = '[\n' + candidate + '\n]';
        try {
          final decoded2 = jsonDecode(wrapped);
          if (decoded2 is List) {
            for (final e in decoded2) {
              if (e is Map) {
                items.add(Map<String, dynamic>.from(e));
              } else {
                errors.add('数组项不是对象，已跳过');
              }
            }
            parsedAsPackage = true;
          }
        } catch (_) {
          // fall through
        }
      }
    }

    if (!parsedAsPackage) {
      final lines = normalized.split(RegExp(r'\r?\n'));
      for (int i = 0; i < lines.length; i++) {
        var raw = lines[i].trim();
        if (raw.isEmpty) continue;
        if (raw.startsWith('#')) continue;
        // remove inline // comments and trailing comma
        raw = raw.replaceFirst(RegExp(r'//.*$'), '').trim();
        raw = raw.replaceFirst(RegExp(r',$'), '').trim();
        try {
          final obj = jsonDecode(raw) as Map<String, dynamic>;
          items.add(obj);
        } catch (_) {
          errors.add('第 ${i + 1} 行: 非法 JSON');
        }
      }
    }

    for (int i = 0; i < items.length; i++) {
      final obj = items[i];

      String _s(String key) => (obj[key] ?? '').toString().trim();
      final word = _s('word');
      final chinese = _s('chinese');
      if (word.isEmpty || chinese.isEmpty) {
        errors.add('第 ${i + 1} 条: 缺少必填字段 word/chinese');
        continue;
      }

      final phonetic = _s('phonetic');
      final phrase = _s('phrase');
      final phraseCn = _s('phrase_cn');
      final sentenceEn = _s('sentence_en');
      final sentenceCn = _s('sentence_cn');

      // enabled
      bool enabled = true;
      final enabledVal = obj['enabled'];
      if (enabledVal != null) {
        final s = enabledVal.toString().trim().toLowerCase();
        if (s == '1' || s == 'true' || s == 'yes' || s == '是' || s == '启用' || s == '真') {
          enabled = true;
        } else if (s == '0' || s == 'false' || s == 'no' || s == '否' || s == '禁用' || s == '假') {
          enabled = false;
        } else {
          errors.add('第 ${i + 1} 条: enabled 值无效，已默认设为启用');
        }
      }

      // related
      final related = <RelatedWord>[];
      final relatedVal = obj['related'];
      if (relatedVal is List) {
        for (final e in relatedVal) {
          try {
            final m = Map<String, dynamic>.from(e as Map);
            related.add(RelatedWord.fromJson(m));
          } catch (_) {
            errors.add('第 ${i + 1} 条: related 元素非法，已忽略');
          }
        }
      } else if (relatedVal != null) {
        errors.add('第 ${i + 1} 条: related 需为数组，已忽略');
      }

      // tags by names
      final effectiveTagIds = <String>{};
      final tagsStr = _s('tags');
      if (tagsStr.isNotEmpty) {
        final names = tagsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final name in names) {
          final existing = tagNameMap[name];
          if (existing != null) {
            effectiveTagIds.add((existing as Tag).id);
          } else {
            final newTag = Tag(id: _uuid.v4(), name: name, userId: userId);
            await _tagRepo.upsert(newTag);
            tagNameMap[name] = newTag;
            effectiveTagIds.add(newTag.id);
          }
        }
      }

      // tags by ids
      final tagIdsStr = _s('tag_ids');
      if (tagIdsStr.isNotEmpty) {
        final ids = tagIdsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final tid in ids) {
          final t = await _tagRepo.findById(tid);
          if (t != null) {
            effectiveTagIds.add(t.id);
          } else {
            errors.add('第 ${i + 1} 条: 未找到 tag_id=$tid，已忽略');
          }
        }
      }

      // visibility: public -> userId=null
      final visibility = _s('visibility').toLowerCase();
      final effectiveUserId = visibility == 'public' ? null : userId;

      // upsert by word+user (case-insensitive)
      WordCard? existing;
      for (final w in existingWords) {
        if ((w.word.trim().toLowerCase() == word.trim().toLowerCase()) && (w.userId == effectiveUserId)) {
          existing = w;
          break;
        }
      }

      if (existing != null) {
        existing.word = word;
        existing.chinese = chinese;
        existing.phonetic = phonetic;
        existing.phrase = phrase;
        existing.phraseCn = phraseCn;
        existing.sentenceEn = sentenceEn;
        existing.sentenceCn = sentenceCn;
        existing.relatedEnabled = related.isNotEmpty;
        existing.related = related;
        existing.enabled = enabled;
        existing.tagIds = effectiveTagIds.toList();
        existing.updatedAt = DateTime.now();
        // 更新场景：暂不做云端 upsert，避免重复。仅更新本地存储。
        await _wordRepo.update(existing);
      } else {
        final w = WordCard(
          id: _uuid.v4(),
          word: word,
          phonetic: phonetic,
          chinese: chinese,
          phrase: phrase,
          phraseCn: phraseCn,
          sentenceEn: sentenceEn,
          sentenceCn: sentenceCn,
          relatedEnabled: related.isNotEmpty,
          related: related,
          enabled: enabled,
          tagIds: effectiveTagIds.toList(),
          userId: effectiveUserId,
        );
        // 优先尝试写入 Supabase 云端；失败再回退到本地
        if (writeRemote && SupabaseService.isInitialized) {
          try {
            final inserted = await WordCardsSupabaseService.createRemote(w);
            if (inserted == null) {
              await _wordRepo.create(w);
            }
          } catch (_) {
            await _wordRepo.create(w);
          }
        } else {
          await _wordRepo.create(w);
        }
        existingWords.add(w);
      }
      imported++;
    }

    return TextImportResult(importedCount: imported, errors: errors);
  }
}