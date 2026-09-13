import 'package:collection/collection.dart';

/// A naive implementation of a node of *SumTree*.
/// A *SumTree* is a data structure each of whose nodes maintains a numerical
/// field [sum] which equals the sum of [sum] of all its children plus its own
/// term, recursively.
/// This version also contains [value] aside from [sum] as with the ordinary
/// trees, which is not taken into account in the [sum] computation.
class SumTreeNode<T> {
  final T value;
  int _sum;
  SumTreeNode<T>? _parent;
  final List<SumTreeNode<T>> children;

  int get sum => _sum;
  SumTreeNode<T>? get parent => _parent;

  /// Create a new SumTree node with the given [value] and [term].
  /// The [sum] of this node will be automatically computed as the sum of
  /// the given [term] and [sum]s of the children.
  SumTreeNode(
    this.value,
    int term, {
    Iterable<SumTreeNode<T>> children = const [],
  }) : _sum = term,
       _parent = null,
       children = List<SumTreeNode<T>>.of(children, growable: true) {
    for (final child in this.children) {
      _sum += child._sum;
      child._parent = this;
    }
  }

  /// Adopt a node [child] as a direct child of this node.
  /// This will update [sum] of this node and all its ancestors.
  /// If the node already has a parent, it will first leave its current parent.
  ///
  /// ## Time Complexity
  /// Average $O(\log n)$ time complexity, though it can be $O(n)$ in the worst
  /// case where the tree is highly unbalanced.
  void adopt(SumTreeNode<T> child) {
    if (child.parent != null) {
      child.leaveParent();
    }

    children.add(child);
    child._parent = this;
    SumTreeNode<T>? ancestor = this;
    while (ancestor != null) {
      ancestor._sum += child._sum;
      ancestor = ancestor._parent;
    }
  }

  /// Remove a direct child [child] from this node.
  /// This will update [sum] of this node and all its ancestors.
  /// If [child] is not a direct child of this node, this method does nothing.
  ///
  /// ## Time Complexity
  /// Average $O(\log n)$ time complexity, though it can be $O(n)$ in the worst
  /// case where the tree is highly unbalanced.
  void disown(SumTreeNode<T> child) {
    if (!children.remove(child)) return;

    child._parent = null;
    SumTreeNode<T>? ancestor = this;
    while (ancestor != null) {
      ancestor._sum -= child._sum;
      ancestor = ancestor._parent;
    }
  }

  /// Remove this node from its parent, if any.
  /// This will update [sum] of the parent and all its ancestors.
  ///
  /// ## Time Complexity
  /// Average $O(\log n)$ time complexity, though it can be $O(n)$ in the worst
  /// case where the tree is highly unbalanced.
  SumTreeNode<T>? leaveParent() {
    final parent = _parent;

    if (parent == null) return null;

    parent.disown(this);
    return parent;
  }

  @override
  String toString() {
    return 'SumTreeNode{value: $value, sum: $_sum, children: $children}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SumTreeNode<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          _sum == other._sum &&
          const ListEquality().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    _parent.hashCode,
    _sum.hashCode,
    const ListEquality().hash(children),
  );
}
