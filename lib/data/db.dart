import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  static final AppDatabase instance = AppDatabase._();
  AppDatabase._();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'ewc.sqlite');
    return openDatabase(
      dbPath,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV1(db);
        await _migrateToV2(db);
        await db.execute('PRAGMA user_version = 2');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
      },
    );
  }

  Future<void> _createV1(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS word_cards (
  id TEXT PRIMARY KEY,
  word TEXT NOT NULL,
  phonetic TEXT DEFAULT '',
  chinese TEXT NOT NULL,
  sentence_en TEXT DEFAULT '',
  sentence_cn TEXT DEFAULT '',
  related_enabled INTEGER NOT NULL DEFAULT 0,
  related_json TEXT NOT NULL DEFAULT '[]',
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS tags (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  color TEXT NOT NULL DEFAULT '#3B82F6',
  description TEXT DEFAULT '',
  created_at INTEGER NOT NULL
);
''');

    await db.execute('''
CREATE TABLE IF NOT EXISTS word_card_tags (
  word_id TEXT NOT NULL,
  tag_id TEXT NOT NULL,
  PRIMARY KEY (word_id, tag_id),
  FOREIGN KEY (word_id) REFERENCES word_cards(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
);
''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_word_cards_enabled ON word_cards(enabled);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_word_card_tags_tag ON word_card_tags(tag_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_word_card_tags_word ON word_card_tags(word_id);');
  }

  Future<void> _migrateToV2(Database db) async {
    await db.execute('ALTER TABLE word_cards ADD COLUMN audio_us TEXT');
    await db.execute('ALTER TABLE word_cards ADD COLUMN audio_uk TEXT');
  }
}