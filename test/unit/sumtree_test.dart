import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/sumtree.dart';

void main() {
  group('SumTreeNode constructor', () {
    test('sum equals term when no children', () {
      final node = SumTreeNode('a', 5);
      expect(node.sum, 5);
    });

    test('sum includes children sums', () {
      final child1 = SumTreeNode('b', 3);
      final child2 = SumTreeNode('c', 7);
      final root = SumTreeNode('a', 2, children: [child1, child2]);
      expect(root.sum, 12);
    });

    test('constructor sets parent on children', () {
      final child = SumTreeNode('b', 1);
      final root = SumTreeNode('a', 0, children: [child]);
      expect(child.parent, same(root));
    });

    test('constructor with no children leaves parent null', () {
      final node = SumTreeNode('a', 10);
      expect(node.parent, isNull);
    });

    test('sum accumulates deeply nested children', () {
      final grandchild = SumTreeNode('c', 4);
      final child = SumTreeNode('b', 1, children: [grandchild]);
      final root = SumTreeNode('a', 2, children: [child]);
      expect(root.sum, 7);
    });
  });

  group('adopt', () {
    test('adds child and updates parent sum', () {
      final root = SumTreeNode('a', 1);
      final child = SumTreeNode('b', 3);
      root.adopt(child);
      expect(root.sum, 4);
      expect(root.children, contains(child));
    });

    test('sets parent on adopted child', () {
      final root = SumTreeNode('a', 0);
      final child = SumTreeNode('b', 5);
      root.adopt(child);
      expect(child.parent, same(root));
    });

    test('updates all ancestors when adopting', () {
      final grandparent = SumTreeNode('g', 1);
      final parent = SumTreeNode('p', 2);
      grandparent.adopt(parent);

      final child = SumTreeNode('c', 10);
      parent.adopt(child);

      expect(parent.sum, 12);
      expect(grandparent.sum, 13);
    });

    test('detaches child from previous parent before adopting', () {
      final oldParent = SumTreeNode('old', 0);
      final newParent = SumTreeNode('new', 0);
      final child = SumTreeNode('c', 5);

      oldParent.adopt(child);
      expect(oldParent.sum, 5);

      newParent.adopt(child);
      expect(child.parent, same(newParent));
      expect(oldParent.children, isNot(contains(child)));
      expect(oldParent.sum, 0);
      expect(newParent.sum, 5);
    });
  });

  group('disown', () {
    test('removes child and updates sum', () {
      final child = SumTreeNode('b', 6);
      final root = SumTreeNode('a', 2, children: [child]);
      root.disown(child);
      expect(root.sum, 2);
      expect(root.children, isNot(contains(child)));
    });

    test('clears parent reference on disowned child', () {
      final child = SumTreeNode('b', 3);
      final root = SumTreeNode('a', 0, children: [child]);
      root.disown(child);
      expect(child.parent, isNull);
    });

    test('updates all ancestors when disowning', () {
      final grandparent = SumTreeNode('g', 1);
      final parent = SumTreeNode('p', 2);
      final child = SumTreeNode('c', 10);
      grandparent.adopt(parent);
      parent.adopt(child);

      parent.disown(child);

      expect(parent.sum, 2);
      expect(grandparent.sum, 3);
    });

    test('does nothing if child is not a direct child', () {
      final root = SumTreeNode('a', 5);
      final unrelated = SumTreeNode('x', 3);
      root.disown(unrelated);
      expect(root.sum, 5);
    });
  });

  group('leaveParent', () {
    test('returns null when node has no parent', () {
      final node = SumTreeNode('a', 1);
      expect(node.leaveParent(), isNull);
    });

    test('returns former parent after leaving', () {
      final parent = SumTreeNode('p', 0);
      final child = SumTreeNode('c', 5);
      parent.adopt(child);
      final result = child.leaveParent();
      expect(result, same(parent));
    });

    test('removes node from parent children and updates sum', () {
      final parent = SumTreeNode('p', 2);
      final child = SumTreeNode('c', 5);
      parent.adopt(child);

      child.leaveParent();

      expect(parent.children, isEmpty);
      expect(parent.sum, 2);
      expect(child.parent, isNull);
    });

    test('updates grandparent sum when child leaves parent', () {
      final grandparent = SumTreeNode('g', 1);
      final parent = SumTreeNode('p', 2);
      final child = SumTreeNode('c', 10);
      grandparent.adopt(parent);
      parent.adopt(child);

      child.leaveParent();

      expect(parent.sum, 2);
      expect(grandparent.sum, 3);
    });
  });

  group('equality', () {
    test('identical nodes are equal', () {
      final node = SumTreeNode('a', 5);
      expect(node, equals(node));
    });

    test('nodes with same value, sum, and children are equal', () {
      final a = SumTreeNode('x', 3, children: [SumTreeNode('y', 2)]);
      final b = SumTreeNode('x', 3, children: [SumTreeNode('y', 2)]);
      expect(a, equals(b));
    });

    test('nodes with different sums are not equal', () {
      final a = SumTreeNode('x', 3);
      final b = SumTreeNode('x', 4);
      expect(a, isNot(equals(b)));
    });

    test('nodes with different values are not equal', () {
      final a = SumTreeNode('x', 3);
      final b = SumTreeNode('y', 3);
      expect(a, isNot(equals(b)));
    });
  });

  group('toString', () {
    test('contains value and sum', () {
      final node = SumTreeNode('hello', 7);
      final s = node.toString();
      expect(s, contains('hello'));
      expect(s, contains('7'));
    });
  });
}
