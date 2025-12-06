import 'dart:convert';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:uuid/uuid.dart';
import '../data/models/word_card.dart';
import '../data/models/tag.dart';
import '../data/repositories/word_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../services/supabase_service.dart';
import '../services/word_cards_supabase_service.dart';

class ExcelImportResult {
  final int importedCount;
  final List<String> errors;
  ExcelImportResult({required this.importedCount, required this.errors});
}

class ExcelImportService {
  final _uuid = const Uuid();
  final WordRepository _wordRepo = WordRepository();
  final TagRepository _tagRepo = TagRepository();

  // Header aliases to support Chinese column names
  static const Map<String, List<String>> _headerAliases = {
    'word': ['word', '单词', '词汇', 'word*', '单词*'],
    'chinese': ['chinese', '中文', '中文释义', '释义', 'chinese*', '中文释义*'],
    'phonetic': ['phonetic', '音标'],
    'phrase': ['phrase', '短语'],
    'phrase_cn': ['phrase_cn', '短语中文'],
    'sentence_en': ['sentence_en', '英文例句', '英文句子'],
    'sentence_cn': ['sentence_cn', '中文例句', '中文句子'],
    'related_json': ['related_json', '相关词JSON', '相关词'],
    'enabled': ['enabled', '启用'],
    'tag_ids': ['tag_ids', '标签ID'],
    'tags': ['tags', '标签名', '标签'],
  };

  // Build an Excel template with header row
  Uint8List buildTemplateBytes({bool chineseHeaders = false}) {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    final headers = chineseHeaders
        ? [
            '单词*',
            '中文释义*',
            '音标',
            '短语',
            '短语中文',
            '英文例句',
            '中文例句',
            '相关词JSON',
            '启用',
            '标签ID',
            '标签名',
          ]
        : [
            'word*',
            'chinese*',
            'phonetic',
            'phrase',
            'phrase_cn',
            'sentence_en',
            'sentence_cn',
            'related_json',
            'enabled',
            'tag_ids',
            'tags',
          ];
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
    // Example row
    sheet.appendRow([
      TextCellValue('leverage'),
      TextCellValue('利用；杠杆作用'),
      TextCellValue('/ˈlevərɪdʒ/'),
      TextCellValue('operational leverage'),
      TextCellValue('经营杠杆'),
      TextCellValue('We leverage data to improve products.'),
      TextCellValue('我们利用数据改进产品。'),
      TextCellValue('[{"word":"lever","chinese":"杠杆"}]'),
      TextCellValue('1'),
      TextCellValue(''),
      TextCellValue('商务英语,金融'),
    ]);
    final bytes = excel.save(fileName: 'word_cards_template.xlsx');
    return Uint8List.fromList(bytes ?? const []);
  }

  Future<ExcelImportResult> importFromBytes(Uint8List bytes, {String? userId}) async {
    final excel = Excel.decodeBytes(bytes);
    final sheetNames = excel.tables.keys.toList();
    if (sheetNames.isEmpty) {
      return ExcelImportResult(importedCount: 0, errors: ['Excel 文件为空或无工作表']);
    }
    final table = excel.tables[sheetNames.first]!;
    final rows = table.rows;
    if (rows.isEmpty) {
      return ExcelImportResult(importedCount: 0, errors: ['Excel 工作表无数据']);
    }

    // Build header -> column index map (support Chinese/English headers)
    final headerRow = rows.first;
    String _h(int idx) {
      if (idx >= headerRow.length) return '';
      final c = headerRow[idx];
      final v = c?.value;
      return v?.toString().trim().replaceAll('*', '') ?? '';
    }
    final colIndex = <String, int>{};
    for (int i = 0; i < headerRow.length; i++) {
      final text = _h(i).toLowerCase();
      if (text.isEmpty) continue;
      for (final entry in _headerAliases.entries) {
        if (entry.value.map((e) => e.toLowerCase().replaceAll('*', '')).contains(text)) {
          colIndex[entry.key] = i;
        }
      }
    }

    // Fallback to default order if not recognized
    void _ensureDefault(String key, int idx) {
      colIndex.putIfAbsent(key, () => idx);
    }
    _ensureDefault('word', 0);
    _ensureDefault('chinese', 1);
    _ensureDefault('phonetic', 2);
    _ensureDefault('phrase', 3);
    _ensureDefault('phrase_cn', 4);
    _ensureDefault('sentence_en', 5);
    _ensureDefault('sentence_cn', 6);
    _ensureDefault('related_json', 7);
    _ensureDefault('enabled', 8);
    _ensureDefault('tag_ids', 9);
    _ensureDefault('tags', 10);

    // Build tag name map for current user
    final existingTags = await _tagRepo.listAll(userId: userId);
    final tagNameMap = <String, Tag>{
      for (final t in existingTags) t.name.trim(): t,
    };

    int imported = 0;
    final errors = <String>[];

    // Start from row index 1 (skip header)
    for (int r = 1; r < rows.length; r++) {
      final row = rows[r];
      String _cellString(int idx) {
        if (idx >= row.length) return '';
        final c = row[idx];
        final v = c?.value;
        return v?.toString().trim() ?? '';
      }

      String g(String key) => _cellString(colIndex[key] ?? -1);

      final word = g('word');
      final chinese = g('chinese');
      if (word.isEmpty || chinese.isEmpty) {
        errors.add('第 ${r + 1} 行: 缺少必填字段 word/chinese');
        continue;
      }

      final phonetic = g('phonetic');
      final phrase = g('phrase');
      final phraseCn = g('phrase_cn');
      final sentenceEn = g('sentence_en');
      final sentenceCn = g('sentence_cn');
      final relatedJsonStr = g('related_json');
      final enabledStr = g('enabled');
      final tagIdsStr = g('tag_ids');
      final tagNamesStr = g('tags');

      // Parse enabled
      bool enabled = true;
      if (enabledStr.isNotEmpty) {
        final s = enabledStr.toLowerCase();
        if (s == '1' || s == 'true' || s == 'yes') {
          enabled = true;
        } else if (s == '0' || s == 'false' || s == 'no') {
          enabled = false;
        } else {
          // 支持中文布尔
          if (s == '是' || s == '启用' || s == '真') {
            enabled = true;
          } else if (s == '否' || s == '禁用' || s == '假') {
            enabled = false;
          } else {
            errors.add('第 ${r + 1} 行: enabled 值无效，已默认设为启用');
          }
        }
      }

      // Parse related_json
      final related = <RelatedWord>[];
      if (relatedJsonStr.isNotEmpty) {
        try {
          final arr = jsonDecode(relatedJsonStr);
          if (arr is List) {
            for (final e in arr) {
              final m = Map<String, dynamic>.from(e as Map);
              related.add(RelatedWord.fromJson(m));
            }
          } else {
            errors.add('第 ${r + 1} 行: related_json 需为数组，已忽略');
          }
        } catch (_) {
          errors.add('第 ${r + 1} 行: related_json 不是合法 JSON，已忽略');
        }
      }

      // Resolve tags by IDs
      final effectiveTagIds = <String>{};
      if (tagIdsStr.isNotEmpty) {
        final ids = tagIdsStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final tid in ids) {
          final t = await _tagRepo.findById(tid);
          if (t != null) {
            effectiveTagIds.add(t.id);
          } else {
            errors.add('第 ${r + 1} 行: 未找到 tag_id=$tid，已忽略');
          }
        }
      }

      // Resolve tags by names (create if missing)
      if (tagNamesStr.isNotEmpty) {
        final names = tagNamesStr.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
        for (final name in names) {
          final existing = tagNameMap[name];
          if (existing != null) {
            effectiveTagIds.add(existing.id);
          } else {
            final newTag = Tag(id: _uuid.v4(), name: name, userId: userId);
            await _tagRepo.upsert(newTag);
            tagNameMap[name] = newTag;
            effectiveTagIds.add(newTag.id);
          }
        }
      }

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
        userId: userId,
      );
      // 构建期开关：开启且 Supabase 已初始化时，优先写入云端
      const writeRemote = bool.fromEnvironment('SUPABASE_WRITE_REMOTE', defaultValue: true);
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
      imported++;
    }

    return ExcelImportResult(importedCount: imported, errors: errors);
  }
}