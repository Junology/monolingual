import 'dart:async';
import 'package:monolingual/core/radix_tree.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/service/database.dart';

/// Interface class for dictionaries, i.e., a storage of [WordRecord] objects.
/// The instances must provide the following methods:
///
/// - [add]/[remove]: async add/remove a [WordRecord] from the dictionary.
/// - [update]: async update an existing [WordRecord] in the dictionary.
/// - [find]: async find a [WordRecord] by its word.
/// - [isearch]: **sync** find words by prefix (incremental search).
abstract interface class Dictionary {
  FutureOr<WordRecord?> find(String word);
  // Returns false if a record with the same word already exists.
  FutureOr<bool> add(WordRecord record);
  // Returns null if no record with the given word exists.
  FutureOr<WordRecord?> remove(String word);
  // Returns false if no record with the given word exists.
  FutureOr<bool> update(WordRecord record);

  // Sync prefix search; implementations must maintain an in-memory key index.
  Iterable<String> isearch(String prefix);
  // Sync index access to words in lexicographical order.
  String atIndex(int index);

  int get size;
}

class _DictionaryNode {
  final WordRecord record;
  _DictionaryNode? next;

  _DictionaryNode(this.record, [this.next]);
}

/// A container for a collection of [WordRecord] objects.
/// The class provides the following methods:
///
/// - [add]/[remove]: Add or remove a [WordRecord] from the dictionary.
/// - [update]: Update an existing [WordRecord] in the dictionary.
/// - [find]: Find a [WordRecord] by its word.
/// - [isearch]: Find words by prefix (incremental search).
///
/// ### Implementation details
/// The class contains [WordRecord] objects in a hashtable with chaining for collision resolution.
/// A [RadixTree] is maintained as a secondary index for prefix search.
class InMemoryDictionary extends Iterable<WordRecord> implements Dictionary {
  int capacity;
  List<_DictionaryNode?> _buckets;
  final RadixTree _radixTree = RadixTree();

  @override
  int get size => _radixTree.size;

  InMemoryDictionary({this.capacity = 16})
    : _buckets = List<_DictionaryNode?>.filled(capacity, null);

  factory InMemoryDictionary.from(
    Iterable<WordRecord> records, {
    int capacity = 16,
  }) {
    final dictionary = InMemoryDictionary(capacity: capacity);
    for (var record in records) {
      dictionary.add(record);
    }
    return dictionary;
  }

  int _hash(String key) => key.hashCode % capacity;

  void _rehash(int newCapacity) {
    final oldBuckets = _buckets;
    capacity = newCapacity;
    _buckets = List<_DictionaryNode?>.filled(capacity, null);

    for (var bucket in oldBuckets) {
      var entry = bucket;
      while (entry != null) {
        final index = _hash(entry.record.word);
        _buckets[index] = _DictionaryNode(entry.record, _buckets[index]);
        entry = entry.next;
      }
    }
  }

  /// Find a node of a given key from the specified bucket in the hashtable.
  /// Returns the node if found, otherwise returns null.
  _DictionaryNode? _findNode(String word, int index) {
    var entry = _buckets[index];
    while (entry != null) {
      if (entry.record.word == word) return entry;
      entry = entry.next;
    }
    return null;
  }

  /// Find a record [WordRecord] by its primary word.
  /// Returns the record if found, otherwise returns null.
  @override
  WordRecord? find(String word) => _findNode(word, _hash(word))?.record;

  /// Updates an existing [WordRecord] in the dictionary.
  /// [record]'s `word` field must match an existing record in the dictionary.
  /// Returns true if the record was updated, false if no record with the given
  /// word exists
  @override
  bool update(WordRecord record) {
    final index = _hash(record.word);
    final node = _findNode(record.word, index);
    if (node == null) return false;
    node.record.replaceVariants(record.variants);
    node.record.replaceSynonyms(record.synonyms);
    node.record.replaceUsageExamples(record.usageExamples);
    return true;
  }

  /// Adds a new [WordRecord] to the dictionary.
  /// Returns true if the record was added, false if a record with the same word already exists.
  @override
  bool add(WordRecord record) {
    final index = _hash(record.word);

    // Check if the word already exists in the bucket
    if (_findNode(record.word, index) != null) return false;

    _buckets[index] = _DictionaryNode(record, _buckets[index]);

    _radixTree.insert(record.word);

    if (size * 2 > capacity) _rehash(capacity * 2);

    return true;
  }

  /// Removes a [WordRecord] from the dictionary by its word.
  /// Returns true if the record was removed, false if no record with the given word exists.
  @override
  WordRecord? remove(String word) {
    final index = _hash(word);
    var entry = _buckets[index];
    WordRecord? removedRecord;

    if (entry == null) return null;

    if (entry.record.word == word) {
      removedRecord = entry.record;
      _buckets[index] = entry.next;
    } else {
      while (entry!.next != null) {
        if (entry.next!.record.word == word) {
          removedRecord = entry.next!.record;
          entry.next = entry.next!.next;
          break;
        }
        entry = entry.next!;
      }
    }

    if (removedRecord != null) {
      _radixTree.delete(word);
      if (size * 6 < capacity && capacity > 16) _rehash(capacity ~/ 2);
    }

    return removedRecord;
  }

  /// Returns all words starting with [key], in lexicographic order.
  @override
  Iterable<String> isearch(String key) => _radixTree.wordsWithPrefix(key);

  @override
  String atIndex(int index) => _radixTree[index];

  /// Subscript operator to find a [WordRecord] by its primary word.
  /// Returns the record if found, otherwise returns null.
  /// It is equivalent to calling [find] method.
  WordRecord? operator [](String word) => find(word);

  @override
  Iterator<WordRecord> get iterator => DictionaryIterator(_buckets.iterator);

  @override
  String toString() {
    final records = <String>[];
    for (var record in this) {
      records.add(record.toString());
    }
    return 'Dictionary(records: [${records.join(', ')}])';
  }
}

/// An iterator for the [Dictionary] class.
class DictionaryIterator implements Iterator<WordRecord> {
  final Iterator<_DictionaryNode?> _currentBucket;
  _DictionaryNode? _currentNode;

  DictionaryIterator(this._currentBucket);

  bool _nextBucket() {
    while (_currentBucket.moveNext()) {
      if (_currentBucket.current != null) {
        _currentNode = _currentBucket.current;
        return true;
      }
    }
    return false;
  }

  @override
  WordRecord get current => _currentNode!.record;

  @override
  bool moveNext() {
    if (_currentNode?.next != null) {
      _currentNode = _currentNode!.next;
      return true;
    }

    return _nextBucket();
  }
}

class DBDictionary implements Dictionary {
  final String name;
  final DBService _service = DBService();
  final RadixTree _radixTree = RadixTree();

  DBDictionary._internal(this.name);

  /// Create and initialize a [DBDictionary] instance from the given dictionary name.
  static Future<DBDictionary> openFromDB(String name) async {
    final dictionary = DBDictionary._internal(name);
    await dictionary._initialize();
    return dictionary;
  }

  Future<void> _initialize() async {
    _service.ensureDictionary(name);
    final rows = await _service.wordsInDictionary(name);
    for (final row in rows) {
      _radixTree.insert(row);
    }
  }

  @override
  Future<WordRecord?> find(String word) => _service.findWord(name, word);

  @override
  Future<bool> add(WordRecord record) async {
    final success = await _service.insertWord(name, record);
    if (!success) return false;
    _radixTree.insert(record.word);
    return true;
  }

  @override
  Future<WordRecord?> remove(String word) async {
    final existing = await find(word);
    if (existing == null) return null;
    await _service.removeWord(name, word);
    _radixTree.delete(word);
    return existing;
  }

  @override
  Future<bool> update(WordRecord record) => _service.updateWord(name, record);

  @override
  Iterable<String> isearch(String prefix) => _radixTree.wordsWithPrefix(prefix);

  @override
  String atIndex(int index) => _radixTree[index];

  @override
  int get size => _radixTree.size;
}
