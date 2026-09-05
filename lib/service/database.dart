import 'dart:io' show Platform;
import 'dart:convert';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:monolingual/core/word_record.dart';

/// Service class for managing the SQLite database connection and schema.
///
class DBService {
  static final DBService _instance = DBService._internal();
  factory DBService() => _instance;
  DBService._internal();

  static Database? _db;

  Database get db {
    assert(_db != null, 'DBService.initialize() has not been called');
    return _db!;
  }

  /// Initialize the database service with the given database path.
  ///
  /// @param dbPath The path to the SQLite database file should be located at.
  /// If not specified, an in-memory database will be used.
  static Future<void> initialize({String dbPath = inMemoryDatabasePath}) async {
    if (Platform.isLinux || Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: _onCreate,
      onOpen: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('CREATE TABLE dictionaries (name TEXT PRIMARY KEY)');
    await db.execute('''
      CREATE TABLE words (
        dictionary_name TEXT NOT NULL,
        word            TEXT NOT NULL,
        variants        TEXT NOT NULL DEFAULT '[]',
        synonyms        TEXT NOT NULL DEFAULT '[]',
        usage_examples  TEXT NOT NULL DEFAULT '[]',
        UNIQUE (dictionary_name, word),
        FOREIGN KEY (dictionary_name) REFERENCES dictionaries (name) ON DELETE CASCADE,
        PRIMARY KEY (dictionary_name, word)
      )
    ''');
  }

  static Map<String, String> _wordRecordToMap(WordRecord record) {
    return {
      'word': record.word,
      'variants': jsonEncode(record.variants),
      'synonyms': jsonEncode(record.synonyms.toList()),
      'usage_examples': jsonEncode(record.usageExamples),
    };
  }

  static WordRecord _mapToWordRecord(Map<String, String> map) {
    return WordRecord.newWord(
      map['word'] as String,
      variants: (jsonDecode(map['variants']!) as List).cast<String>(),
      synonyms: (jsonDecode(map['synonyms']!) as List).cast<String>(),
      usageExamples: (jsonDecode(map['usage_examples']!) as List)
          .cast<String>(),
    );
  }

  /// Get an iterable of all dictionary names stored in the database.
  Future<Iterable<String>> dictionaryNames() async {
    assert(_db != null, 'DBService.initialize() has not been called');
    final rows = await _db!.query('dictionaries', orderBy: 'name');
    return rows.map((r) => r['name'] as String);
  }

  /// Ensure that a dictionary with the given name exists in the database.
  /// If the dictionary does not exist, it will be created.
  Future<void> ensureDictionary(String name) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    await _db!.insert('dictionaries', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Delete a dictionary from the database.
  /// @warning This will also delete all words associated with the dictionary
  /// due to the `ON DELETE CASCADE` constraint.
  Future<void> deleteDictionary(String name) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    // Cascade deletes associated rows in `words`.
    await _db!.delete('dictionaries', where: 'name = ?', whereArgs: [name]);
  }

  Future<Iterable<String>> wordsInDictionary(String dictionaryName) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    final rows = await _db!.query(
      'words',
      columns: ['word'],
      where: 'dictionary_name = ?',
      whereArgs: [dictionaryName],
      orderBy: 'word',
    );
    return rows.map((r) => r['word'] as String);
  }

  Future<WordRecord?> findWord(String dictionaryName, String word) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    final rows = await _db!.query(
      'words',
      where: 'dictionary_name = ? AND word = ?',
      whereArgs: [dictionaryName, word],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return _mapToWordRecord({
      'word': row['word'] as String,
      'variants': row['variants'] as String,
      'synonyms': row['synonyms'] as String,
      'usage_examples': row['usage_examples'] as String,
    });
  }

  Future<bool> insertWord(String dictionaryName, WordRecord record) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    try {
      await _db!.insert(
        'words',
        _wordRecordToMap(record)..['dictionary_name'] = dictionaryName,
      );
      return true;
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        return false;
      }
      rethrow;
    }
  }

  Future<WordRecord?> removeWord(String dictionaryName, String word) async {
    // TODO: Think about the use of `RETURNING` clause instead of find-then-delete (SQLite >= 3.35)
    assert(_db != null, 'DBService.initialize() has not been called');
    final existing = await findWord(dictionaryName, word);
    if (existing == null) return null;
    await _db!.delete(
      'words',
      where: 'dictionary_name = ? AND word = ?',
      whereArgs: [dictionaryName, word],
    );
    return existing;
  }

  Future<bool> updateWord(String dictionaryName, WordRecord record) async {
    assert(_db != null, 'DBService.initialize() has not been called');
    // Databse.update returns the number of rows affected.
    // Hence, the function return `0` if the word is not found in the dictionary.
    final count = await _db!.update(
      'words',
      _wordRecordToMap(record),
      where: 'dictionary_name = ? AND word = ?',
      whereArgs: [dictionaryName, record.word],
    );
    return count > 0;
  }
}
