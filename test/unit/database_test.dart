import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/service/database.dart';

void main() {
  setUp(() async {
    // Close any previously opened in-memory DB so sqflite doesn't return it
    // from its cache and we always start with a fresh schema.
    try {
      await DBService().db.close();
    } on AssertionError {
      // DB was not yet initialized; nothing to close.
    }
    await DBService.initialize();
  });

  group('DBService.dictionaryNames()', () {
    test('returns empty iterable when no dictionaries exist', () async {
      final names = await DBService().dictionaryNames();
      expect(names, isEmpty);
    });

    test('returns dictionary names sorted alphabetically', () async {
      final service = DBService();
      await service.ensureDictionary('beta');
      await service.ensureDictionary('alpha');
      final names = await service.dictionaryNames();
      expect(names.toList(), orderedEquals(['alpha', 'beta']));
    });
  });

  group('DBService.ensureDictionary()', () {
    test('creates a new dictionary', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(await service.dictionaryNames(), contains('mydict'));
    });

    test('is idempotent when called twice with the same name', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await expectLater(service.ensureDictionary('mydict'), completes);
      expect((await service.dictionaryNames()).toList(), ['mydict']);
    });
  });

  group('DBService.deleteDictionary()', () {
    test('removes the dictionary', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.deleteDictionary('mydict');
      expect(await service.dictionaryNames(), isNot(contains('mydict')));
    });

    test('cascades deletion to words in the dictionary', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      await service.deleteDictionary('mydict');
      await service.ensureDictionary('mydict');
      expect(await service.wordsInDictionary('mydict'), isEmpty);
    });
  });

  group('DBService.wordsInDictionary()', () {
    test('returns empty iterable when dictionary has no words', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(await service.wordsInDictionary('mydict'), isEmpty);
    });

    test('returns words sorted alphabetically', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('banana'));
      await service.insertWord('mydict', WordRecord.newWord('apple'));
      final words = await service.wordsInDictionary('mydict');
      expect(words.toList(), orderedEquals(['apple', 'banana']));
    });
  });

  group('DBService.findWord()', () {
    test('returns null when word does not exist', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(await service.findWord('mydict', 'nonexistent'), isNull);
    });

    test('returns the matching word record', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      final record = WordRecord.newWord(
        'hello',
        synonyms: ['hi'],
        usageExamples: ['Hello world.'],
      );
      await service.insertWord('mydict', record);
      final found = await service.findWord('mydict', 'hello');
      expect(found, isNotNull);
      expect(found!.word, 'hello');
      expect(found.synonyms, contains('hi'));
      expect(found.usageExamples, contains('Hello world.'));
    });
  });

  group('DBService.insertWord()', () {
    test('returns true on successful insertion', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(
        await service.insertWord('mydict', WordRecord.newWord('hello')),
        isTrue,
      );
    });

    test('returns false when word already exists', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      expect(
        await service.insertWord('mydict', WordRecord.newWord('hello')),
        isFalse,
      );
    });

    test('persists variants, synonyms, and usage examples', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      final record = WordRecord.newWord(
        'test',
        variants: ['tests', 'tested'],
        synonyms: ['exam'],
        usageExamples: ['Run the test.'],
      );
      await service.insertWord('mydict', record);
      final found = await service.findWord('mydict', 'test');
      expect(found!.variants, containsAll(['tests', 'tested']));
      expect(found.synonyms, contains('exam'));
      expect(found.usageExamples, contains('Run the test.'));
    });
  });

  group('DBService.removeWord()', () {
    test('returns null when word does not exist', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(await service.removeWord('mydict', 'nonexistent'), isNull);
    });

    test('returns the removed word record', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      final removed = await service.removeWord('mydict', 'hello');
      expect(removed, isNotNull);
      expect(removed!.word, 'hello');
    });

    test('word is absent after removal', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      await service.removeWord('mydict', 'hello');
      expect(await service.findWord('mydict', 'hello'), isNull);
    });
  });

  group('DBService.updateWord()', () {
    test('returns false when word does not exist', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      expect(
        await service.updateWord('mydict', WordRecord.newWord('nonexistent')),
        isFalse,
      );
    });

    test('returns true on successful update', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      expect(
        await service.updateWord(
          'mydict',
          WordRecord.newWord('hello', synonyms: ['hi']),
        ),
        isTrue,
      );
    });

    test('persists updated fields', () async {
      final service = DBService();
      await service.ensureDictionary('mydict');
      await service.insertWord('mydict', WordRecord.newWord('hello'));
      await service.updateWord(
        'mydict',
        WordRecord.newWord(
          'hello',
          variants: ['hellooo'],
          synonyms: ['hi', 'hey'],
          usageExamples: ['Hello there.'],
        ),
      );
      final found = await service.findWord('mydict', 'hello');
      expect(found!.variants, contains('hellooo'));
      expect(found.synonyms, containsAll(['hi', 'hey']));
      expect(found.usageExamples, contains('Hello there.'));
    });
  });
}
