import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/radix_tree.dart';

void main() {
  group('RadixTree()', () {
    test('creates an empty tree', () {
      final tree = RadixTree();
      expect(tree.wordsWithPrefix(''), isEmpty);
    });
  });

  group('RadixTree.fromIterable()', () {
    test('creates a tree containing all provided words', () {
      final tree = RadixTree.fromIterable(['apple', 'app', 'apply']);
      expect(tree.wordsWithPrefix(''), containsAll(['apple', 'app', 'apply']));
    });

    test('creates an empty tree from an empty iterable', () {
      expect(RadixTree.fromIterable([]).wordsWithPrefix(''), isEmpty);
    });

    test('duplicate words are stored only once', () {
      final tree = RadixTree.fromIterable(['word', 'word', 'word']);
      expect(tree.wordsWithPrefix('').toList(), orderedEquals(['word']));
    });
  });

  group('RadixTree.insert()', () {
    late RadixTree tree;
    setUp(() => tree = RadixTree());

    test('returns true for a new word', () {
      expect(tree.insert('hello'), isTrue);
    });

    test('inserted word appears in the tree', () {
      tree.insert('hello');
      expect(tree.wordsWithPrefix('hello'), contains('hello'));
    });

    test('returns false for a duplicate word', () {
      tree.insert('hello');
      expect(tree.insert('hello'), isFalse);
    });

    test('returns false for an empty string', () {
      expect(tree.insert(''), isFalse);
    });

    test('inserts a word that is a prefix of an existing word', () {
      tree.insert('testing');
      tree.insert('test');
      expect(tree.wordsWithPrefix('test'), containsAll(['test', 'testing']));
    });

    test('inserts a word that extends an existing word', () {
      tree.insert('test');
      tree.insert('testing');
      expect(tree.wordsWithPrefix('test'), containsAll(['test', 'testing']));
    });

    test('inserts words with no common prefix', () {
      tree.insert('apple');
      tree.insert('banana');
      expect(tree.wordsWithPrefix(''), containsAll(['apple', 'banana']));
    });

    test('inserts words that share only a partial prefix (triggers split)', () {
      tree.insert('test');
      tree.insert('team');
      expect(tree.wordsWithPrefix('te'), containsAll(['test', 'team']));
    });
  });

  group('RadixTree.delete()', () {
    late RadixTree tree;
    setUp(() {
      tree = RadixTree.fromIterable([
        'test',
        'testing',
        'tested',
        'exam',
        'examine',
      ]);
    });

    test('returns true for an existing word', () {
      expect(tree.delete('test'), isTrue);
    });

    test('deleted word is absent from the tree', () {
      tree.delete('exam');
      expect(tree.wordsWithPrefix('exam'), isNot(contains('exam')));
    });

    test('returns false for a non-existent word', () {
      expect(tree.delete('nonexistent'), isFalse);
    });

    test('returns false for an empty string', () {
      expect(tree.delete(''), isFalse);
    });

    test('deleting a prefix word does not remove its extensions', () {
      tree.delete('test');
      expect(tree.wordsWithPrefix('test'), containsAll(['testing', 'tested']));
      expect(tree.wordsWithPrefix('test'), isNot(contains('test')));
    });

    test('deleting an extended word does not remove its prefix', () {
      tree.delete('testing');
      expect(tree.wordsWithPrefix('test'), containsAll(['test', 'tested']));
      expect(tree.wordsWithPrefix('test'), isNot(contains('testing')));
    });

    test(
      'triggers path compression when a branch collapses to a single child',
      () {
        tree.delete('exam');
        expect(tree.wordsWithPrefix('ex'), orderedEquals(['examine']));
        expect(tree.wordsWithPrefix('exam'), orderedEquals(['examine']));
      },
    );

    test(
      'returns false when the target is only a partial match in the tree',
      () {
        expect(tree.delete('examinee'), isFalse);
      },
    );

    test('tree becomes empty after deleting the only word', () {
      final single = RadixTree.fromIterable(['only']);
      single.delete('only');
      expect(single.wordsWithPrefix(''), isEmpty);
    });
  });

  group('RadixTree.wordsWithPrefix()', () {
    late RadixTree tree;
    setUp(() {
      tree = RadixTree.fromIterable([
        'test',
        'testing',
        'tested',
        'app',
        'apple',
        'apply',
        'banana',
      ]);
    });

    test('returns all words for an empty prefix', () {
      expect(
        tree.wordsWithPrefix(''),
        containsAll([
          'test',
          'testing',
          'tested',
          'app',
          'apple',
          'apply',
          'banana',
        ]),
      );
    });

    test('yields words in lexicographic order', () {
      expect(
        tree.wordsWithPrefix(''),
        orderedEquals([
          'app',
          'apple',
          'apply',
          'banana',
          'test',
          'tested',
          'testing',
        ]),
      );
    });

    test('returns empty for a non-existent prefix', () {
      expect(tree.wordsWithPrefix('xyz'), isEmpty);
    });

    test('returns exactly the word itself when it has no extensions', () {
      expect(tree.wordsWithPrefix('banana'), orderedEquals(['banana']));
    });

    test('returns the exact word and all its extensions in order', () {
      expect(
        tree.wordsWithPrefix('test'),
        orderedEquals(['test', 'tested', 'testing']),
      );
    });

    test('returns extensions for a prefix shorter than any stored word', () {
      expect(
        tree.wordsWithPrefix('ap'),
        orderedEquals(['app', 'apple', 'apply']),
      );
    });

    test('returns empty on an empty tree', () {
      expect(RadixTree().wordsWithPrefix('anything'), isEmpty);
    });

    test('reflects subsequent insertions', () {
      tree.insert('tester');
      expect(tree.wordsWithPrefix('test'), contains('tester'));
    });

    test('reflects subsequent deletions', () {
      tree.delete('testing');
      expect(tree.wordsWithPrefix('test'), isNot(contains('testing')));
      expect(tree.wordsWithPrefix('test'), containsAll(['test', 'tested']));
    });
  });
}
