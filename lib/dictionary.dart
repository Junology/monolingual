import 'package:monolingual/word_record.dart';

class _DictionaryNode {
  final WordRecord record;
  _DictionaryNode? next;

  _DictionaryNode(this.record, [this.next]);
}

/// A container for a collection of [WordRecord] objects.
/// The class provides the following methods:
///
/// - [add]/[remove]: Add or remove a [WordRecord] from the dictionary.
/// - [find]: Find a [WordRecord] by its word.
///
/// ### Implementation details
/// The class contains [WordRecord] objects in a hashtable with chaining for collision resolution.
class Dictionary extends Iterable<WordRecord> {
  int capacity;
  int size;
  List<_DictionaryNode?> _buckets;

  Dictionary({this.capacity = 16})
    : _buckets = List<_DictionaryNode?>.filled(capacity, null),
      size = 0;

  factory Dictionary.from(Iterable<WordRecord> records, {int capacity = 16}) {
    final dictionary = Dictionary(capacity: capacity);
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
  WordRecord? find(String word) => _findNode(word, _hash(word))?.record;

  /// Adds a new [WordRecord] to the dictionary.
  /// Returns true if the record was added, false if a record with the same word already exists.
  bool add(WordRecord record) {
    final index = _hash(record.word);

    // Check if the word already exists in the bucket
    if (_findNode(record.word, index) != null) return false;

    _buckets[index] = _DictionaryNode(record, _buckets[index]);
    size++;

    if (size * 2 > capacity) _rehash(capacity * 2);

    return true;
  }

  /// Removes a [WordRecord] from the dictionary by its word.
  /// Returns true if the record was removed, false if no record with the given word exists.
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
      size--;
      if (size * 6 < capacity && capacity > 16) _rehash(capacity ~/ 2);
    }

    return removedRecord;
  }

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
