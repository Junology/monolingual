import 'dart:collection';
import 'package:vector_math/vector_math.dart';

/// A basic binary min-heap implementation.
class _MinHeap {
  final List<({int key, int value})> _heap;

  _MinHeap._(this._heap);

  factory _MinHeap.empty() => _MinHeap._(const []);
  factory _MinHeap.heapify(List<({int key, int value})> elements) {
    final heap = _MinHeap._(List.from(elements));
    for (int i = (heap._heap.length >> 1) - 1; i >= 0; i--) {
      heap._heapDown(i);
    }
    return heap;
  }

  /// Swap two elements in the heap at the given indices.
  void _swap(int i, int j) {
    final aux = _heap[i];
    _heap[i] = _heap[j];
    _heap[j] = aux;
  }

  void _heapUp(int index) {
    while (index > 0) {
      final parentIndex = (index - 1) >> 1;
      if (_heap[index].key >= _heap[parentIndex].key) break;
      _swap(index, parentIndex);
      index = parentIndex;
    }
  }

  void _heapDown(int index) {
    final length = _heap.length;
    while (true) {
      final left = (index << 1) + 1;
      final right = left + 1;
      int smallest = index;

      if (left < length && _heap[left].key < _heap[smallest].key) {
        smallest = left;
        if (right < length && _heap[right].key < _heap[smallest].key) {
          smallest = right;
        }
      }
      if (smallest == index) break;
      _swap(index, smallest);
      index = smallest;
    }
  }

  bool get isEmpty => _heap.isEmpty;

  /// Insert a new element into the heap.
  void insert(int key, int value) {
    _heap.add((key: key, value: value));
    _heapUp(_heap.length - 1);
  }

  /// Remove and return the element with the smallest key from the heap.
  ({int key, int value}) extractMin() {
    if (_heap.isEmpty) {
      throw StateError('Heap is empty');
    }
    final min = _heap[0];
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _heapDown(0);
    }
    return min;
  }
}

/// A directed integer-weighted graph with vertices of type [V].
/// @note Won't support deletion of vertices or edges.
class Graph<V> {
  /// The maximum distance value used to represent "infinity" in shortest path calculations.
  static const int maxDistance = 1 << 52;

  final List<List<({int target, int weight})>> adjacencyList = [];
  HashMap<V, int> vertexIndexMap = HashMap();

  Graph({Iterable<V> vertices = const []}) {
    for (final vertex in vertices) {
      _addVertexInternal(vertex);
    }
  }

  Iterable<V> get vertices => vertexIndexMap.keys;
  int get vertexCount => adjacencyList.length;

  void _addVertexInternal(V vertex) {
    vertexIndexMap[vertex] = adjacencyList.length;
    adjacencyList.add([]);
  }

  /// Add a vertex to the graph. Do nothing when the vertex already exists.
  ///
  /// @return `true` if the vertex was added, `false` if it already existed.
  bool addVertex(V vertex) {
    if (vertexIndexMap.containsKey(vertex)) {
      return false;
    }
    _addVertexInternal(vertex);
    return true;
  }

  /// Add a directed edge from [source] to [target] with the given [weight].
  ///
  /// @return `true` if the edge was added, `false` if either the source or
  /// target vertex does not exist or the weight is negative.
  /// @warning The method adds an edge even if it already exists, potentially creating duplicate edges.
  bool addEdge(V source, V target, int weight) {
    if (weight < 0) return false;
    final sourceIndex = vertexIndexMap[source];
    final targetIndex = vertexIndexMap[target];
    if (sourceIndex == null || targetIndex == null) return false;

    adjacencyList[sourceIndex].add((target: targetIndex, weight: weight));
    return true;
  }

  /// Add a bidirectional edge between [source] and [target] with the given [weight].
  /// The method is equivalent to calling [addEdge(source, target, weight)] and
  /// [addEdge(target, source, weight)].
  ///
  /// @warning The method adds edges even if they already exist, potentially creating duplicate edges.
  bool addBidirectionalEdge(V source, V target, int weight) {
    if (weight < 0) return false;
    final sourceIndex = vertexIndexMap[source];
    final targetIndex = vertexIndexMap[target];
    if (sourceIndex == null || targetIndex == null) return false;

    adjacencyList[sourceIndex].add((target: targetIndex, weight: weight));
    adjacencyList[targetIndex].add((target: sourceIndex, weight: weight));
    return true;
  }

  /// Set the adjacency list for [vertex] with the given [edges].
  /// The method replaces any existing adjacency list for the vertex.
  ///
  /// @throws ArgumentError if [vertex] or any target vertex in [edges] does not exist.
  void setAdjacency(V vertex, Iterable<({V target, int weight})> edges) {
    final vertexIndex = vertexIndexMap[vertex];
    if (vertexIndex == null) throw ArgumentError('Unknown vertex.');

    adjacencyList[vertexIndex] = edges.map((e) {
      final targetIndex = vertexIndexMap[e.target];
      if (targetIndex == null) throw ArgumentError('Unknown target vertex.');

      return (target: targetIndex, weight: e.weight);
    }).toList();
  }

  /// Compute the shortest path distances from the [source] vertex to all vertices.
  /// The method is implemented using Dijkstra's algorithm with a priority queue
  /// built on a simple binary heap.
  ///
  /// @returns A [HashMap] mapping each vertex to its shortest path distance from [source].
  /// @note If a vertex is unreachable from [source], its distance will be set to [maxDistance].
  HashMap<V, int> dijkstraShortestPath(V source) {
    final sourceIndex = vertexIndexMap[source];
    if (sourceIndex == null) return HashMap<V, int>();

    final n = adjacencyList.length;
    final d = List<int>.filled(n, maxDistance);
    final visited = List<bool>.filled(n, false);
    final heap = _MinHeap.empty();

    d[sourceIndex] = 0;
    heap.insert(0, sourceIndex);

    while (!heap.isEmpty) {
      final current = heap.extractMin();

      if (visited[current.value]) continue;

      for (final edge in adjacencyList[current.value]) {
        final next = edge.target;
        final weight = edge.weight;
        final dNext = d[current.value] + weight;
        if (dNext < d[next]) {
          d[next] = dNext;
          heap.insert(dNext, next);
        }
      }

      visited[current.value] = true;
    }

    final result = HashMap<V, int>.fromEntries(
      vertexIndexMap.entries.map((e) => MapEntry(e.key, d[e.value])),
    );
    return result;
  }

  /// Compute a planar layout for the graph using a Kamada-Kawai algorithm.
  /// Only the positions of vertices present in [initialPositions] will be
  /// computed though the other vertices affects the overall layout.
  ///
  /// @param initialPositions A [HashMap] containing the initial positions of vertices.
  /// @param scale A scaling factor for the layout.
  /// @param tolerance The convergence tolerance for the algorithm.
  /// @returns A [HashMap] mapping each vertex to its 2D position as a [Vector2].
  HashMap<V, Vector2> kamadaKawaiLayout(
    HashMap<V, Vector2> initialPositions, {
    required double scale,
    double tolerance = 1e-8,
  }) {
    HashMap<V, Vector2> positions = HashMap<V, Vector2>.from(initialPositions);
    // TODO: Implementation of the Kamada-Kawai algorithm would go here.
    return positions;
  }
}
