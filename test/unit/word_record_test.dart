import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/word_record.dart';

void main() {
  group('WordRecord.newWord() factory', () {
    test(
      'initializes variants, synonyms, and usageExamples to empty when omitted',
      () {
        final record = WordRecord.newWord('hello');
        expect(record.word, 'hello');
        expect(record.variants, isEmpty);
        expect(record.synonyms, isEmpty);
        expect(record.usageExamples, isEmpty);
      },
    );

    test('sorts variants in ascending order', () {
      final record = WordRecord.newWord(
        'test',
        variants: ['zzz', 'aaa', 'mmm'],
      );
      expect(record.variants, orderedEquals(['aaa', 'mmm', 'zzz']));
    });

    test('preserve synonyms', () {
      final record = WordRecord.newWord('test', synonyms: ['c', 'a', 'b']);
      expect(record.synonyms, unorderedEquals(['c', 'a', 'b']));
    });

    test('preserve usageExamples', () {
      final record = WordRecord.newWord(
        'test',
        usageExamples: ['first', 'second'],
      );
      expect(record.usageExamples, unorderedEquals(['first', 'second']));
    });

    test('explicit empty lists produce empty collections', () {
      final record = WordRecord.newWord(
        'word',
        variants: [],
        synonyms: [],
        usageExamples: [],
      );
      expect(record.variants, isEmpty);
      expect(record.synonyms, isEmpty);
      expect(record.usageExamples, isEmpty);
    });
  });

  group('WordRecord.clone()', () {
    late WordRecord original;

    setUp(() {
      original = WordRecord.newWord(
        'test',
        variants: ['tested', 'tests'],
        synonyms: ['exam', 'quiz'],
        usageExamples: ['Take the test.'],
      );
    });

    test('clone compares equal to the original', () {
      expect(original.clone(), equals(original));
    });

    test('clone word equals the original word', () {
      expect(original.clone().word, original.word);
    });

    test('mutating clone variants does not affect the original', () {
      original.clone().variants.add('testing');
      expect(original.variants, isNot(contains('testing')));
    });

    test('mutating clone synonyms does not affect the original', () {
      original.clone().synonyms.add('trial');
      expect(original.synonyms, isNot(contains('trial')));
    });

    test('mutating clone usageExamples does not affect the original', () {
      original.clone().usageExamples.add('Another example.');
      expect(original.usageExamples, hasLength(1));
    });
  });

  group('Variants', () {
    late WordRecord record;

    // newWord sorts variants: ['runs', 'running'] -> ['running', 'runs']
    setUp(
      () => record = WordRecord.newWord('run', variants: ['runs', 'running']),
    );

    test('addVariant returns true for a new variant', () {
      expect(record.addVariant('ran'), isTrue);
    });

    test('addVariant inserts in sorted order', () {
      record.addVariant('ran'); // 'ran' < 'running' < 'runs'
      expect(record.variants, orderedEquals(['ran', 'running', 'runs']));
    });

    test('addVariant returns false for an existing variant', () {
      expect(record.addVariant('runs'), isFalse);
    });

    test('addVariant does not insert duplicates', () {
      record.addVariant('runs');
      expect(record.variants.where((v) => v == 'runs'), hasLength(1));
    });

    test('removeVariant returns true for an existing variant', () {
      expect(record.removeVariant('runs'), isTrue);
    });

    test('removeVariant removes the variant from the list', () {
      record.removeVariant('runs');
      expect(record.variants, isNot(contains('runs')));
    });

    test('removeVariant returns false for a non-existent variant', () {
      expect(record.removeVariant('nonexistent'), isFalse);
    });

    test('replaceVariants replaces all variants and sorts them', () {
      record.replaceVariants(['zzz', 'aaa']);
      expect(record.variants, orderedEquals(['aaa', 'zzz']));
    });

    test('replaceVariants with empty list clears all variants', () {
      record.replaceVariants([]);
      expect(record.variants, isEmpty);
    });
  });

  group('Synonyms', () {
    late WordRecord record;

    setUp(
      () => record = WordRecord.newWord('test', synonyms: ['exam', 'quiz']),
    );

    test('addSynonym returns true for a new synonym', () {
      expect(record.addSynonym('trial'), isTrue);
    });

    test('addSynonym adds the synonym', () {
      record.addSynonym('trial');
      expect(record.synonyms, contains('trial'));
    });

    test('addSynonym increments synonymsCount', () {
      record.addSynonym('trial');
      expect(record.synonymsCount, 3);
    });

    test('addSynonym returns false for a duplicate synonym', () {
      expect(record.addSynonym('exam'), isFalse);
    });

    test('addSynonym does not insert duplicates', () {
      record.addSynonym('exam');
      expect(record.synonyms.where((s) => s == 'exam'), hasLength(1));
    });

    test('removeSynonym returns true for an existing synonym', () {
      expect(record.removeSynonym('exam'), isTrue);
    });

    test('removeSynonym removes the synonym', () {
      record.removeSynonym('exam');
      expect(record.synonyms, isNot(contains('exam')));
    });

    test('removeSynonym decrements synonymsCount', () {
      record.removeSynonym('exam');
      expect(record.synonymsCount, 1);
    });

    test('removeSynonym returns false for a non-existent synonym', () {
      expect(record.removeSynonym('nonexistent'), isFalse);
    });

    test('replaceSynonyms replaces the synonym set', () {
      record.replaceSynonyms(['verify', 'check']);
      expect(record.synonyms.toList(), orderedEquals(['verify', 'check']));
      expect(record.synonyms, isNot(contains('exam')));
    });

    test('replaceSynonyms with empty iterable clears all synonyms', () {
      record.replaceSynonyms([]);
      expect(record.synonyms, isEmpty);
    });
  });

  group('Usage examples', () {
    late WordRecord record;

    setUp(() {
      record = WordRecord.newWord(
        'test',
        usageExamples: ['First example.', 'Second example.'],
      );
    });

    test('addUsageExample appends to the end', () {
      record.addUsageExample('Third example.');
      expect(record.usageExamples.last, 'Third example.');
      expect(record.usageExamples, hasLength(3));
    });

    test('addUsageExample allows duplicate entries', () {
      record.addUsageExample('First example.');
      expect(
        record.usageExamples.where((e) => e == 'First example.'),
        hasLength(2),
      );
    });

    test('removeUsageExampleAt returns true for a valid index', () {
      expect(record.removeUsageExampleAt(0), isTrue);
    });

    test('removeUsageExampleAt removes the example at the given index', () {
      record.removeUsageExampleAt(0);
      expect(record.usageExamples, orderedEquals(['Second example.']));
    });

    test('removeUsageExampleAt returns false for a negative index', () {
      expect(record.removeUsageExampleAt(-1), isFalse);
    });

    test('removeUsageExampleAt returns false for an out-of-bounds index', () {
      expect(record.removeUsageExampleAt(2), isFalse);
    });

    test('replaceUsageExamples replaces the list', () {
      record.replaceUsageExamples(['Only example.']);
      expect(record.usageExamples, orderedEquals(['Only example.']));
    });

    test('replaceUsageExamples with empty list clears all examples', () {
      record.replaceUsageExamples([]);
      expect(record.usageExamples, isEmpty);
    });
  });

  group('Equality', () {
    final testRecord = WordRecord.newWord(
      'test',
      variants: ['tests'],
      synonyms: ['experiment', 'exam', 'quiz'],
      usageExamples: ['This test can be failed.'],
    );
    final examRecord = WordRecord.newWord(
      'exam',
      variants: ['exams'],
      synonyms: ['test', 'quiz'],
      usageExamples: ['This exam can be failed.'],
    );
    final quizRecord = WordRecord.newWord(
      'quiz',
      variants: ['quizzes'],
      synonyms: ['test', 'exam', 'tease'],
      usageExamples: ['This quiz can be failed.'],
    );

    test('a record equals itself', () {
      expect(testRecord, equals(testRecord));
      expect(examRecord, equals(examRecord));
      expect(quizRecord, equals(quizRecord));
    });

    test('two records with identical fields are equal', () {
      final duplicate = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['experiment', 'exam', 'quiz'],
        usageExamples: ['This test can be failed.'],
      );
      expect(testRecord, equals(duplicate));
    });

    test('records with different words are not equal', () {
      expect(testRecord, isNot(equals(examRecord)));
      expect(testRecord, isNot(equals(quizRecord)));
      expect(examRecord, isNot(equals(quizRecord)));
    });

    test('records with different variants are not equal', () {
      final other = WordRecord.newWord(
        'test',
        variants: ['tests', 'tested'],
        synonyms: ['experiment', 'exam', 'quiz'],
        usageExamples: ['This test can be failed.'],
      );
      expect(testRecord, isNot(equals(other)));
    });

    test('records with different synonyms are not equal', () {
      final other = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['verify', 'check', 'try'],
        usageExamples: ['This test can be failed.'],
      );
      expect(testRecord, isNot(equals(other)));
    });

    test('records with different usage examples are not equal', () {
      final other = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['experiment', 'exam', 'quiz'],
        usageExamples: ['This should be tested correctly.'],
      );
      expect(testRecord, isNot(equals(other)));
    });
  });

  group('Hash code', () {
    test('equal WordRecords have the same hash code', () {
      final r1 = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['exam'],
        usageExamples: ['Example.'],
      );
      final r2 = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['exam'],
        usageExamples: ['Example.'],
      );
      expect(r1, equals(r2));
      expect(r1.hashCode, equals(r2.hashCode));
    });
  });

  group('String representation', () {
    test('toString contains word, variants, synonyms, and usageExamples', () {
      final record = WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['exam'],
        usageExamples: ['Use it in a sentence.'],
      );
      final s = record.toString();
      expect(s, contains('test'));
      expect(s, contains('tests'));
      expect(s, contains('exam'));
      expect(s, contains('Use it in a sentence.'));
    });

    test('toString has the expected format', () {
      final record = WordRecord.newWord(
        'word',
        variants: ['words'],
        synonyms: ['term'],
        usageExamples: ['A word.'],
      );
      expect(
        record.toString(),
        'WordRecord(word: word, variants: [words], synonyms: {term}, usageExamples: [A word.])',
      );
    });
  });
}
