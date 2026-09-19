/// Returns the length of the common prefix between two strings, starting from
/// a given offset in the second string.
///
/// @pre `offset` must be a valid index in string `b`.
int _commonPrefixLength(String a, String b, int offset) {
  final bLength = b.length - offset;
  final len = a.length < bLength ? a.length : bLength;
  for (var i = 0; i < len; i++) {
    if (a[i] != b[i + offset]) return i;
  }
  return len;
}

class _RadixNode {
  String label;
  int count;
  final List<_RadixNode> children;

  bool get isEnd => children.isEmpty || children[0].label.isEmpty;

  _RadixNode(this.label, this.children, this.count);

  void collapseSoleDescendant() {
    if (children.length == 1) {
      final soleChild = children[0];
      label += soleChild.label;
      children.clear();
      children.addAll(soleChild.children);
    }
  }

  /// Perform a binary search to find a child node whose label starts with the
  /// given character.
  /// If such a child exists, returns `(true, index)` where index is the position
  /// of the child in the [children] list.
  /// Otherwise, returns `(false, index)` where index is the index where a new
  /// child with the given character should be inserted to maintain sorted order.
  (bool found, int index) findChildStartingWith(String char) {
    int low = 0, high = children.length - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final c = children[mid];
      if (c.label.isEmpty || c.label[0].compareTo(char) < 0) {
        low = mid + 1;
      } else if (c.label[0] == char) {
        return (true, mid);
      } else {
        high = mid - 1;
      }
    }
    return (false, low); // low is the insertion point
  }

  @override
  String toString() => '_RadixNode(label: $label, children: $children)';
}

/// A radix tree (compressed trie) supporting O(|prefix| + |results|) prefix search.
/// Words are yielded in lexicographic order.
class RadixTree {
  final _RadixNode _root = _RadixNode('', [], 0);

  RadixTree();

  int get size => _root.count;

  factory RadixTree.fromIterable(Iterable<String> words) {
    final tree = RadixTree();
    for (var word in words) {
      tree.insert(word);
    }
    return tree;
  }

  /// Insert a word into [RadixTree].
  /// Returns true if the word was added, false if it already existed.
  ///
  /// @param word The word to insert.
  /// @return True if the word was added, false if it already existed.
  /// @remark If [word] is empty, it does nothing and returns `false`.
  bool insert(String word) {
    if (word.isEmpty) return false;

    // var node = _root;
    final List<_RadixNode> path = [_root];
    int offset = 0;

    while (offset < word.length) {
      final node = path.last;
      final firstChar = word[offset];

      // Find the child of the current node whose [label] starts with the
      // same character as the remaining part of the word.
      final (bool found, int index) = node.findChildStartingWith(firstChar);

      // If no child starts with the same character, create a new child node for
      // the remaining part of the word.
      if (!found) {
        final newNode = _RadixNode(word.substring(offset), [], 1);
        // If the current node is the tail of a word, then we need to add an
        // empty node as a child to mark the end of the word.
        if (node.label.isNotEmpty && node.children.isEmpty) {
          node.children.addAll([_RadixNode('', [], 1), newNode]);
        } else {
          node.children.insert(index, newNode);
        }
        break;
      }

      final child = node.children[index];

      final lcp = _commonPrefixLength(child.label, word, offset);

      // The common prefix is shorter than the label.
      if (lcp < child.label.length) {
        // Split the child at the common prefix
        final prefix = child.label.substring(0, lcp);
        final oldNode = _RadixNode(
          child.label.substring(lcp),
          child.children,
          child.count,
        );
        final newNode = _RadixNode(word.substring(offset + lcp), [], 1);

        // Split the child node into two nodes
        node.children[index] = _RadixNode(
          prefix,
          oldNode.label.compareTo(newNode.label) < 0
              ? [oldNode, newNode]
              : [newNode, oldNode],
          oldNode.count + 1,
        );
        break;
      }

      // Turns out that the searching word is contained within the label.
      if (lcp == word.length - offset) {
        // Search word is exhausted.

        if (child.children.isEmpty || child.children[0].label.isEmpty) {
          // Word already exists
          return false;
        }

        // Add an empty node as a marker for the end of the word.
        child.children.insert(0, _RadixNode('', [], 1));
        break;
      }

      path.add(child);
      offset += lcp;
    }

    if (offset >= word.length) return false;

    for (final node in path) {
      ++node.count;
    }

    return true;
  }

  /// Delete a word from [RadixTree]
  /// Return `true` if the word was found and deleted, `false` otherwise.
  /// @remark If [word] is empty, it does nothing and returns `false`.
  bool delete(String word) {
    final path = <_RadixNode>[_root];
    int offset = 0;

    while (offset < word.length) {
      final node = path.last;
      final firstChar = word[offset];

      final (bool found, int index) = node.findChildStartingWith(firstChar);
      if (!found) return false;

      final child = node.children[index];
      final lcp = _commonPrefixLength(child.label, word, offset);

      if (lcp < child.label.length) return false;

      if (offset + lcp == word.length) {
        // Found the word.

        if (child.children.isEmpty) {
          node.children.removeAt(index);
          node.collapseSoleDescendant();
          break;
        } else if (child.children[0].label.isEmpty) {
          child.children.removeAt(0);
          child.collapseSoleDescendant();
          break;
        } else {
          return false;
        }
      }
      path.add(child);
      offset += lcp;
    }

    if (offset >= word.length) return false;

    for (final node in path) {
      --node.count;
    }
    return true;
  }

  /// Index access to words in lexicographic order.
  ///
  /// ### Note
  /// The operator returns unspecified results without crashing if the index is
  /// out of bounds.
  String operator [](int index) {
    var node = _root;
    String word = '';

    while (index < node.count) {
      for (final child in node.children) {
        if (index < child.count) {
          word += node.label;
          node = child;
          break;
        }
        index -= child.count;
      }
      if (node.children.isEmpty) break;
    }
    return word + node.label;
  }

  /// Find the lowest common ancestor (LCA) node for words having the given prefix.
  (String accumulated, _RadixNode node)? _findLCA(String prefix) {
    var node = _root;
    String accumulated = '';
    int offset = 0;

    while (offset < prefix.length) {
      accumulated += node.label;
      final firstChar = prefix[offset];

      final (bool found, int index) = node.findChildStartingWith(firstChar);
      if (!found) return null;

      final child = node.children[index];
      final lcp = _commonPrefixLength(child.label, prefix, offset);

      if (lcp < child.label.length) {
        if (offset + lcp == prefix.length) {
          return (accumulated, child);
        } else {
          return null;
        }
      }

      node = child;
      offset += lcp;
    }

    return (accumulated, node);
  }

  /// Count the number of words in [RadixTree] that have the given prefix.
  int countWordsWithPrefix(String prefix) {
    final lca = _findLCA(prefix);
    if (lca == null) return 0;
    return lca.$2.count;
  }

  /// Traverse all words in [RadixTree] that have the given prefix.
  Iterable<String> wordsWithPrefix(String prefix) sync* {
    final lca = _findLCA(prefix);
    if (lca == null) return;
    final (accumulated, node) = lca;
    yield* _collectAll(node, accumulated);
  }

  Iterable<String> _collectAll(_RadixNode node, String prefix) sync* {
    final nextPrefix = prefix + node.label;
    if (node.children.isEmpty && nextPrefix.isNotEmpty) {
      yield nextPrefix;
    }

    for (final child in node.children) {
      yield* _collectAll(child, nextPrefix);
    }
  }
}
