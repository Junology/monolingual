import 'package:collection/collection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/service/database.dart';

List<WordRecord> _makeTestRecords() => [
  WordRecord.newWord(
    'test',
    variants: ['tests'],
    synonyms: ['experiment', 'exam', 'quiz'],
    usageExamples: ['This test can be failed.'],
  ),
  WordRecord.newWord(
    'exam',
    variants: ['exams'],
    synonyms: ['test', 'quiz'],
    usageExamples: ['This exam can be failed.'],
  ),
  WordRecord.newWord(
    'quiz',
    variants: ['quizzes'],
    synonyms: ['test', 'exam', 'tease'],
    usageExamples: ['This quiz can be failed.'],
  ),
];

// Registers the tests shared by all Dictionary implementations.
// Getters are used so each test reads the instance set up by the enclosing setUp.
void _registerSharedTests({
  required Dictionary Function() dictionary,
  required List<WordRecord> Function() testWords,
}) {
  test('size reflects number of records', () {
    expect(dictionary().size, testWords().length);
  });

  group('find()', () {
    test('returns the matching record', () async {
      for (final word in testWords()) {
        expect(await dictionary().find(word.word), equals(word));
      }
    });

    test('returns null for a non-existent word', () async {
      if (testWords().any((word) => word.word == 'nonexistent')) {
        fail('Test setup error: "nonexistent" should not be in testWords');
      }
      expect(await dictionary().find('nonexistent'), isNull);
    });
  });

  group('add()', () {
    test('returns true and stores the record', () async {
      final words = testWords();
      if (words.any((word) => word.word == 'new')) {
        fail('Test setup error: "new" should not be in testWords');
      }
      final newRecord = WordRecord.newWord(
        'new',
        variants: ['new'],
        synonyms: ['fresh'],
        usageExamples: ['This is a new word.'],
      );

      expect(await dictionary().add(newRecord), isTrue);
      expect(dictionary().size, words.length + 1);
      expect(await dictionary().find('new'), equals(newRecord));
      for (final word in words) {
        expect(await dictionary().find(word.word), equals(word));
      }
    });

    test('returns false for a duplicate word', () async {
      final words = testWords();
      final first = words.first;
      final duplicate = WordRecord.newWord(
        first.word,
        variants: first.variants.map((v) => '${v}_new').toList(),
        synonyms: first.synonyms.map((s) => '${s}_new').toList(),
        usageExamples: first.usageExamples,
      );

      expect(await dictionary().add(duplicate), isFalse);
      expect(dictionary().size, words.length);
      for (final word in words) {
        expect(await dictionary().find(word.word), equals(word));
      }
    });
  });

  group('remove()', () {
    test('returns the removed record and deletes it', () async {
      final words = testWords();
      if (words.any((word) => word.word == 'new')) {
        fail('Test setup error: "new" should not be in testWords');
      }
      final newRecord = WordRecord.newWord(
        'new',
        variants: ['new'],
        synonyms: ['fresh'],
        usageExamples: ['This is a new word.'],
      );
      await dictionary().add(newRecord);

      final removed = await dictionary().remove('new');
      expect(removed, equals(newRecord));
      expect(dictionary().size, words.length);
      expect(await dictionary().find('new'), isNull);
      for (final word in words) {
        expect(await dictionary().find(word.word), equals(word));
      }
    });

    test('returns null for a non-existent word', () async {
      final words = testWords();
      if (words.any((word) => word.word == 'nonexistent')) {
        fail('Test setup error: "nonexistent" should not be in testWords');
      }
      expect(await dictionary().remove('nonexistent'), isNull);
      expect(dictionary().size, words.length);
    });
  });

  group('update()', () {
    test('returns false for a non-existent word', () async {
      final words = testWords();
      if (words.any((word) => word.word == 'nonexistent')) {
        fail('Test setup error: "nonexistent" should not be in testWords');
      }
      expect(
        await dictionary().update(WordRecord.newWord('nonexistent')),
        isFalse,
      );
      expect(dictionary().size, words.length);
    });

    test('returns true and persists the updated fields', () async {
      final words = testWords();
      final original = words.first;
      // Build updated record before calling update() since InMemoryDictionary
      // mutates the stored object in-place (which is the same as words.first).
      final updated = WordRecord.newWord(
        original.word,
        variants: original.variants.map((v) => '${v}_u').toList(),
        synonyms: original.synonyms.map((s) => '${s}_u').toList(),
        usageExamples: original.usageExamples.map((e) => '${e}_u').toList(),
      );

      expect(await dictionary().update(updated), isTrue);
      expect(dictionary().size, words.length);
      expect(await dictionary().find(original.word), equals(updated));
      for (final word in words.skip(1)) {
        expect(await dictionary().find(word.word), equals(word));
      }
    });
  });

  group('isearch', () {
    test('returns all words for empty prefix', () {
      final words = testWords();
      expect(
        dictionary().isearch(''),
        orderedEquals(words.map((word) => word.word).sorted()),
      );
    });

    test('returns words for specified prefixes', () {
      final words = testWords();
      for (final prefix in ['qu', 'test', 'xyz']) {
        expect(
          dictionary().isearch(prefix),
          orderedEquals(
            words
                .map((word) => word.word)
                .where((word) => word.startsWith(prefix))
                .sorted(),
          ),
        );
      }
    });

    test('reflect word addition and removal', () async {
      final words = testWords();
      if (words.any((word) => word.word.startsWith('new'))) {
        fail(
          'Test setup error: words starting with "new" should not be in testWords',
        );
      }
      for (final word in words) {
        expect(
          await dictionary().add(WordRecord.newWord('new_${word.word}')),
          isTrue,
        );
      }
      final searchResult = dictionary().isearch('new_');
      expect(searchResult.length, words.length);
      expect(
        searchResult,
        orderedEquals(words.map((word) => 'new_${word.word}').sorted()),
      );
      for (final word in words) {
        expect(await dictionary().remove('new_${word.word}'), isNotNull);
      }
      expect(dictionary().isearch('new_'), isEmpty);
    });

    test(
      'reflects word addition and removal of words with a prefix shared with existing words',
      () async {
        final words = testWords();
        if (words.any((word) => word.word.endsWith('_new'))) {
          fail(
            'Test setup error: words ending with "_new" should not be in testWords',
          );
        }
        for (final word in words) {
          expect(
            await dictionary().add(WordRecord.newWord('${word.word}_new')),
            isTrue,
          );
        }
        for (final word in words) {
          expect(
            dictionary().isearch(word.word),
            orderedEquals(
              words
                  .where((w) => w.word.startsWith(word.word))
                  .expand((w) => [w.word, '${w.word}_new'])
                  .sorted(),
            ),
          );
        }
        for (final word in words) {
          expect(await dictionary().remove('${word.word}_new'), isNotNull);
        }
        for (final word in words) {
          expect(
            dictionary().isearch(word.word),
            orderedEquals(
              words
                  .map((w) => w.word)
                  .where((w) => w.startsWith(word.word))
                  .sorted(),
            ),
          );
        }
      },
    );
  });
}

void main() {
  group('InMemoryDictionary', () {
    late InMemoryDictionary dictionary;
    late List<WordRecord> testWords;

    setUp(() {
      testWords = _makeTestRecords();
      dictionary = InMemoryDictionary.from(testWords);
    });

    _registerSharedTests(
      dictionary: () => dictionary,
      testWords: () => testWords,
    );

    group('[] operator', () {
      test('returns the matching record', () {
        for (final word in testWords) {
          expect(dictionary[word.word], equals(word));
        }
      });

      test('returns null for a non-existent word', () {
        if (testWords.any((w) => w.word == 'nonexistent')) {
          fail('Test setup error: "nonexistent" should not be in testWords');
        }
        expect(dictionary['nonexistent'], isNull);
      });
    });

    test('remains consistent after rehash', () async {
      if (testWords.any((w) => w.word.startsWith('newword'))) {
        fail('Test setup error: "newword*" should not be in testWords');
      }
      const newRecordsCount = 100;
      final initialSize = dictionary.size;
      final initialRecords = dictionary.toList();

      for (int i = 0; i < newRecordsCount; i++) {
        dictionary.add(WordRecord.newWord('newword$i'));
      }
      expect(dictionary.size, initialSize + newRecordsCount);
      for (final record in initialRecords) {
        expect(dictionary.find(record.word), equals(record));
      }

      for (int i = 0; i < newRecordsCount; i++) {
        dictionary.remove('newword$i');
      }
      expect(dictionary.size, initialSize);
      expect(dictionary, containsAll(initialRecords));
    });

    // find() returns a shared reference; in-place mutations are visible through [].
    test('records retrieved via find() are shared references', () async {
      final target = testWords.first;
      final targetWord = target.word;
      final targetSynonymCount = target.synonymsCount;

      if (target.synonyms.any((s) => s.startsWith('new'))) {
        fail(
          'Test setup error: synonyms should not start with "new*" in the test record $target.',
        );
      }
      final record = dictionary.find(targetWord);
      expect(record!.synonymsCount, targetSynonymCount);

      expect(record.addSynonym('newSynonym'), isTrue);
      expect(dictionary[targetWord]!.synonymsCount, targetSynonymCount + 1);
      expect(dictionary[targetWord]!.synonyms, contains('newSynonym'));

      expect(record.addSynonym('newSynonym'), isFalse);
      expect(record.synonymsCount, targetSynonymCount + 1);

      expect(record.removeSynonym('newSynonym'), isTrue);
      expect(dictionary[targetWord]!.synonymsCount, targetSynonymCount);
      expect(dictionary[targetWord]!.synonyms, isNot(contains('newSynonym')));
    });

    test('iterator visits all records', () {
      expect(dictionary.length, testWords.length);
      expect(
        dictionary.map((r) => r.word).toSet(),
        containsAll(testWords.map((w) => w.word)),
      );
    });
  });

  group('DBDictionary', () {
    late DBDictionary dictionary;
    late List<WordRecord> testWords;

    setUp(() async {
      const dictName = 'dict';
      testWords = _makeTestRecords();

      try {
        await DBService().db.close();
      } on AssertionError {
        // Ignore assertion errors in DB closing.
      }
      await DBService.initialize(preferNonIsolate: true);
      final service = DBService();
      await service.ensureDictionary(dictName);
      for (final word in testWords) {
        await service.insertWord(dictName, word);
      }

      dictionary = await DBDictionary.openFromDB(dictName);
    });

    _registerSharedTests(
      dictionary: () => dictionary,
      testWords: () => testWords,
    );
  });
}
