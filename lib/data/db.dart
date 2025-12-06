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
      version: 7,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV1(db);
        await _migrateToV2(db);
        await _migrateToV3(db);
        await _migrateToV4(db);
        await _migrateToV5(db);
        await _migrateToV6(db);
        await _migrateToV7(db);
        await db.execute('PRAGMA user_version = 7');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _migrateToV2(db);
        }
        if (oldVersion < 3) {
          await _migrateToV3(db);
        }
        if (oldVersion < 4) {
          await _migrateToV4(db);
        }
        if (oldVersion < 5) {
          await _migrateToV5(db);
        }
        if (oldVersion < 6) {
          await _migrateToV6(db);
        }
        if (oldVersion < 7) {
          await _migrateToV7(db);
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

  Future<void> _migrateToV3(Database db) async {
    await db.execute('ALTER TABLE word_cards ADD COLUMN user_id TEXT');
    await db.execute('ALTER TABLE tags ADD COLUMN user_id TEXT');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_word_cards_user ON word_cards(user_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_tags_user ON tags(user_id)');
  }

  Future<void> _migrateToV4(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS study_logs (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  word_id TEXT,
  session_id TEXT,
  duration INTEGER NOT NULL,
  viewed_at INTEGER NOT NULL
);
''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_logs_user ON study_logs(user_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_logs_session ON study_logs(session_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_study_logs_word ON study_logs(word_id);');

    await db.execute('''
CREATE TABLE IF NOT EXISTS user_settings (
  user_id TEXT PRIMARY KEY,
  sync_enabled INTEGER NOT NULL DEFAULT 1,
  last_sync_at INTEGER,
  preferences TEXT DEFAULT '{}'
);
''');

    // Add sync_version columns for conflict resolution baseline
    await db.execute('ALTER TABLE word_cards ADD COLUMN sync_version INTEGER NOT NULL DEFAULT 0');
    await db.execute('ALTER TABLE tags ADD COLUMN sync_version INTEGER NOT NULL DEFAULT 0');
  }

  Future<void> _migrateToV5(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS study_plans (
  user_id TEXT PRIMARY KEY,
  target_words INTEGER NOT NULL DEFAULT 10,
  review_cycle INTEGER NOT NULL DEFAULT 7,
  reminder_time TEXT DEFAULT '20:00',
  streak_days INTEGER NOT NULL DEFAULT 0,
  completed_today INTEGER NOT NULL DEFAULT 0,
  updated_at INTEGER NOT NULL
);
''');
  }

  Future<void> _migrateToV6(Database db) async {
    await db.execute('ALTER TABLE word_cards ADD COLUMN phrase TEXT DEFAULT \'\'');
    await db.execute('ALTER TABLE word_cards ADD COLUMN phrase_cn TEXT DEFAULT \'\'');
  }

  Future<void> _migrateToV7(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS carousel_plans (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  user_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_carousel_plans_user ON carousel_plans(user_id);');

    await db.execute('''
CREATE TABLE IF NOT EXISTS carousel_plan_words (
  plan_id TEXT NOT NULL,
  word_id TEXT NOT NULL,
  PRIMARY KEY (plan_id, word_id),
  FOREIGN KEY (plan_id) REFERENCES carousel_plans(id) ON DELETE CASCADE,
  FOREIGN KEY (word_id) REFERENCES word_cards(id) ON DELETE CASCADE
);
''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpw_plan ON carousel_plan_words(plan_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_cpw_word ON carousel_plan_words(word_id);');
  }
}