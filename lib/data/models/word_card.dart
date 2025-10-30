import 'dart:convert';

class RelatedWord {
  final String word;
  final String phonetic;
  final String chinese;
  const RelatedWord({required this.word, this.phonetic = '', this.chinese = ''});

  Map<String, dynamic> toJson() => {
        'word': word,
        'phonetic': phonetic,
        'chinese': chinese,
      };

  factory RelatedWord.fromJson(Map<String, dynamic> j) => RelatedWord(
        word: j['word'] ?? '',
        phonetic: j['phonetic'] ?? '',
        chinese: j['chinese'] ?? '',
      );
}

class WordCard {
  final String id; // uuid
  String word;
  String phonetic;
  String chinese;
  String sentenceEn;
  String sentenceCn;
  bool relatedEnabled;
  List<RelatedWord> related;
  bool enabled;
  List<String> tagIds; // app 层缓存
  DateTime createdAt;
  DateTime updatedAt;
  String? audioPathUs;
  String? audioPathUk;

  WordCard({
    required this.id,
    required this.word,
    this.phonetic = '',
    required this.chinese,
    this.sentenceEn = '',
    this.sentenceCn = '',
    this.relatedEnabled = false,
    this.related = const [],
    this.enabled = true,
    this.tagIds = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.audioPathUs,
    this.audioPathUk,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'chinese': chinese,
        'sentence_en': sentenceEn,
        'sentence_cn': sentenceCn,
        'related_enabled': relatedEnabled,
        'related': related.map((e) => e.toJson()).toList(),
        'enabled': enabled,
        'tag_ids': tagIds,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'audio_us': audioPathUs,
        'audio_uk': audioPathUk,
      };

  factory WordCard.fromJson(Map<String, dynamic> j) => WordCard(
    id: j['id'],
    word: j['word'] ?? '',
    phonetic: j['phonetic'] ?? '',
    chinese: j['chinese'] ?? '',
    sentenceEn: j['sentence_en'] ?? '',
    sentenceCn: j['sentence_cn'] ?? '',
    relatedEnabled: (j['related_enabled'] ?? false) == true,
    related: (j['related'] as List? ?? [])
        .map((e) => RelatedWord.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    enabled: (j['enabled'] ?? true) == true,
    tagIds: (j['tag_ids'] as List? ?? []).map((e) => e.toString()).toList(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(j['created_at'] ?? DateTime.now().millisecondsSinceEpoch),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(j['updated_at'] ?? DateTime.now().millisecondsSinceEpoch),
    audioPathUs: j['audio_us'] as String?,
    audioPathUk: j['audio_uk'] as String?,
  );

  Map<String, dynamic> toDbMap() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'chinese': chinese,
        'sentence_en': sentenceEn,
        'sentence_cn': sentenceCn,
        'related_enabled': relatedEnabled ? 1 : 0,
        'related_json': jsonEncode(related.map((e) => e.toJson()).toList()),
        'enabled': enabled ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
        'audio_us': audioPathUs,
        'audio_uk': audioPathUk,
      };

  factory WordCard.fromDbMap(Map<String, Object?> m) => WordCard(
        id: (m['id'] as String?) ?? '',
        word: (m['word'] as String?) ?? '',
        phonetic: (m['phonetic'] as String?) ?? '',
        chinese: (m['chinese'] as String?) ?? '',
        sentenceEn: (m['sentence_en'] as String?) ?? '',
        sentenceCn: (m['sentence_cn'] as String?) ?? '',
        relatedEnabled: ((m['related_enabled'] as int?) ?? 0) == 1,
        related: List<Map<String, dynamic>>.from(jsonDecode((m['related_json'] as String?) ?? '[]'))
            .map(RelatedWord.fromJson)
            .toList(),
        enabled: ((m['enabled'] as int?) ?? 1) == 1,
        tagIds: const [],
        createdAt: DateTime.fromMillisecondsSinceEpoch((m['created_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
        updatedAt: DateTime.fromMillisecondsSinceEpoch((m['updated_at'] as int?) ?? DateTime.now().millisecondsSinceEpoch),
        audioPathUs: m['audio_us'] as String?,
        audioPathUk: m['audio_uk'] as String?,
      );
}