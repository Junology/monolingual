import 'package:monolingual/word_record.dart';
import 'package:monolingual/dictionary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final WordRecord testRecord = WordRecord.newWord(
    'test',
    variants: ['tests'],
    synonyms: ['experiment', 'exam', 'quiz'],
    usageExamples: ['This test can be failed.'],
  );
  final WordRecord examRecord = WordRecord.newWord(
    'exam',
    variants: ['exams'],
    synonyms: ['test', 'quiz'],
    usageExamples: ['This exam can be failed.'],
  );
  final WordRecord quizRecord = WordRecord.newWord(
    'quiz',
    variants: ['quizzes'],
    synonyms: ['test', 'exam', 'tease'],
    usageExamples: ['This quiz can be failed.'],
  );
  final dictionary = Dictionary.from([testRecord, examRecord, quizRecord]);

  test('WordRecord should be compared correctly', () {
    expect(testRecord, equals(testRecord));
    expect(examRecord, equals(examRecord));
    expect(quizRecord, equals(quizRecord));
    expect(testRecord, isNot(equals(examRecord)));
    expect(testRecord, isNot(equals(quizRecord)));
    expect(examRecord, isNot(equals(testRecord)));
    expect(examRecord, isNot(equals(quizRecord)));
    expect(quizRecord, isNot(equals(testRecord)));
    expect(quizRecord, isNot(equals(examRecord)));
    final anotherTestRecord = WordRecord.newWord(
      'test',
      variants: ['tests', 'tested'],
      synonyms: ['verify', 'check', 'try'],
      usageExamples: ['This should be tested correctly.'],
    );
    expect(testRecord, isNot(equals(anotherTestRecord)));
  });

  test('Dictionary should contain the correct number of records', () {
    expect(dictionary.size, 3);
  });

  test('Dictionary should find records by word', () {
    final testRecord1 = dictionary.find('test');
    expect(testRecord1, isNotNull);
    expect(testRecord1!.word, 'test');
    expect(testRecord1.variants, contains('tests'));
    expect(testRecord1.synonyms, containsAll(['experiment', 'exam', 'quiz']));
    expect(testRecord1.usageExamples, contains('This test can be failed.'));

    final testRecord2 = dictionary.find('exam');
    expect(testRecord2, isNotNull);
    expect(testRecord2!.word, 'exam');
    expect(testRecord2.variants, contains('exams'));
    expect(testRecord2.synonyms, containsAll(['test', 'quiz']));
    expect(testRecord2.usageExamples, contains('This exam can be failed.'));

    final testRecord3 = dictionary.find('quiz');
    expect(testRecord3, isNotNull);
    expect(testRecord3!.word, 'quiz');
    expect(testRecord3.variants, contains('quizzes'));
    expect(testRecord3.synonyms, containsAll(['test', 'exam', 'tease']));
    expect(testRecord3.usageExamples, contains('This quiz can be failed.'));
  });

  test('Dictionary should find records using the index operator', () {
    final testRecord1 = dictionary['test'];
    expect(testRecord1, isNotNull);
    expect(testRecord1, equals(testRecord));

    final testRecord2 = dictionary['exam'];
    expect(testRecord2, isNotNull);
    expect(testRecord2, equals(examRecord));

    final testRecord3 = dictionary['quiz'];
    expect(testRecord3, isNotNull);
    expect(testRecord3, equals(quizRecord));
  });

  test('Dictionary should return null for non-existent records', () {
    final testRecord1 = dictionary.find('nonexistent');
    expect(testRecord1, isNull);

    final testRecord2 = dictionary['nonexistent'];
    expect(testRecord2, isNull);
  });

  test('Dictionary should add and remove records correctly', () {
    final newRecord = WordRecord.newWord(
      'new',
      variants: ['new'],
      synonyms: ['fresh'],
      usageExamples: ['This is a new word.'],
    );

    // Add the new record
    final added = dictionary.add(newRecord);
    expect(added, isTrue);
    expect(dictionary.size, 4);
    expect(dictionary.find('new'), isNotNull);
    expect(dictionary.find('new'), equals(newRecord));
    expect(dictionary.find('test'), isNotNull);
    expect(dictionary.find('exam'), isNotNull);
    expect(dictionary.find('quiz'), isNotNull);

    // Remove the new record
    final removedRecord = dictionary.remove('new');
    expect(removedRecord, isNotNull);
    expect(removedRecord!.word, 'new');
    expect(dictionary.size, 3);
    expect(dictionary.find('new'), isNull);
    expect(dictionary.find('test'), isNotNull);
    expect(dictionary.find('exam'), isNotNull);
    expect(dictionary.find('quiz'), isNotNull);
  });

  test('Dictionary should not add duplicate records', () {
    final anotherTestRecord = WordRecord.newWord(
      'test',
      variants: ['tests', 'tested'],
      synonyms: ['verify', 'check', 'try'],
      usageExamples: ['This should be tested correctly.'],
    );

    final added = dictionary.add(anotherTestRecord);
    expect(added, isFalse);
    expect(dictionary.size, 3);
    expect(dictionary.find('test'), isNotNull);
    expect(dictionary.find('test'), equals(testRecord));
  });

  test('Dictionary should not remove non-existent records', () {
    final removedRecord = dictionary.remove('nonexistent');
    expect(removedRecord, isNull);
    expect(dictionary.size, 3);
    expect(dictionary.find('test'), isNotNull);
    expect(dictionary.find('exam'), isNotNull);
    expect(dictionary.find('quiz'), isNotNull);
  });

  test('Dictionary should be consistent after rehash', () {
    final int newRecordsCount = 100;
    final initialSize = dictionary.size;
    final initialRecords = dictionary.toList();

    // Force a rehash by adding enough records
    for (int i = 0; i < newRecordsCount; i++) {
      dictionary.add(WordRecord.newWord('word$i'));
    }

    expect(dictionary.size, initialSize + newRecordsCount);
    for (var record in initialRecords) {
      expect(dictionary.find(record.word), isNotNull);
      expect(dictionary.find(record.word), equals(record));
    }

    // Force to shrink the dictionary by removing records
    for (int i = 0; i < newRecordsCount; i++) {
      dictionary.remove('word$i');
    }
    expect(dictionary.size, initialSize);
    expect(dictionary, containsAll(initialRecords));
  });

  test('Dictionary should have editable records', () {
    final testRecord = dictionary.find('test');
    expect(testRecord, isNotNull);
    expect(testRecord!.synonymsCount, 3);

    // Add a new synonym
    final added = testRecord.addSynonym('trial');
    expect(added, isTrue);
    expect(dictionary['test']!.synonymsCount, 4);
    expect(dictionary['test']!.synonyms, contains('trial'));

    // Try to add the same synonym again
    final addedAgain = testRecord.addSynonym('trial');
    expect(addedAgain, isFalse);
    expect(testRecord.synonymsCount, 4);

    // Remove a synonym
    final removed = testRecord.removeSynonym('trial');
    expect(removed, isTrue);
    expect(dictionary['test']!.synonymsCount, 3);
    expect(dictionary['test']!.synonyms, isNot(contains('trial')));
  });

  test('DictionaryIterator should iterate over all records', () {
    expect(dictionary.length, 3);
    final words = dictionary.map((record) => record.word).toSet();
    expect(words, containsAll(['test', 'exam', 'quiz']));
  });
}
