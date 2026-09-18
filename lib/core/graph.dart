import 'dart:math';
import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart'; // for debug
import 'package:vector_math/vector_math_64.dart';

typedef GraphWeight = int;
typedef GraphVertex = Vector2;

/// A basic binary min-heap implementation.
class _MinHeap {
  final List<({GraphWeight key, int value})> _heap;

  _MinHeap._(this._heap);

  /// Creates an empty min-heap.
  factory _MinHeap.empty() => _MinHeap._([]);

  /// Creates a min-heap from an existing list of elements.
  // ignore: unused_element
  factory _MinHeap.heapify(List<({GraphWeight key, int value})> elements) {
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
  void insert(GraphWeight key, int value) {
    _heap.add((key: key, value: value));
    _heapUp(_heap.length - 1);
  }

  /// Remove and return the element with the smallest key from the heap.
  ({GraphWeight key, int value}) extractMin() {
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
  static const GraphWeight maxDistance = 0x10000000000000; // = 1 << 52

  final List<({V key, Map<int, GraphWeight> adjacency})> _nodes;
  final HashMap<V, int> _vertexIndexMap;

  /// The constructor for internal use
  Graph._internal(this._nodes, this._vertexIndexMap);

  /// Create a graph with the given set of vertices.
  Graph({Iterable<V> vertices = const []})
    : _nodes = [],
      _vertexIndexMap = HashMap() {
    for (final vertex in vertices) {
      _addVertexInternal(vertex);
    }
  }

  /// Deep copy constructor.
  Graph.from(Graph<V> other)
    : _nodes = List<({V key, Map<int, GraphWeight> adjacency})>.from(
        other._nodes.map(
          (e) =>
              (key: e.key, adjacency: Map<int, GraphWeight>.from(e.adjacency)),
        ),
      ),
      _vertexIndexMap = HashMap.from(other._vertexIndexMap);

  /// Returns an iterable of all vertices in the graph.
  Iterable<V> get vertices => _vertexIndexMap.keys;
  int get vertexCount => _nodes.length;

  /// Returns an iterable of all edges in the graph as a tuple of source, target,
  /// and weight, i.e., `({V source, V target, int weight})`.
  Iterable<({V source, V target, GraphWeight weight})> get edges sync* {
    for (final node in _nodes) {
      final source = node.key;
      for (final edge in node.adjacency.entries) {
        final target = _nodes[edge.key].key;
        final weight = edge.value;
        yield (source: source, target: target, weight: weight);
      }
    }
  }

  int get edgeCount =>
      _nodes.fold(0, (count, node) => count + node.adjacency.length);

  @override
  int get hashCode => Object.hash(
    UnorderedIterableEquality<V>().hash(_vertexIndexMap.keys),
    UnorderedIterableEquality<({V source, V target, GraphWeight weight})>()
        .hash(edges),
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Graph<V>) return false;
    return UnorderedIterableEquality<V>().equals(
          _vertexIndexMap.keys,
          other._vertexIndexMap.keys,
        ) &&
        UnorderedIterableEquality<({V source, V target, GraphWeight weight})>()
            .equals(edges, other.edges);
  }

  /// Check if the graph contains the given [vertex].
  bool containsVertex(V vertex) => _vertexIndexMap.containsKey(vertex);

  /// Get the weight of the edge from [source] to [target].
  /// Returns `null` if either vertex does not exist or there is no edge between them.
  GraphWeight? getWeight(V source, V target) {
    final sourceIndex = _vertexIndexMap[source];
    final targetIndex = _vertexIndexMap[target];
    if (sourceIndex == null || targetIndex == null) return null;
    return _nodes[sourceIndex].adjacency[targetIndex];
  }

  void _addVertexInternal(V vertex) {
    _vertexIndexMap[vertex] = _nodes.length;
    _nodes.add((key: vertex, adjacency: {}));
  }

  /// Add a vertex to the graph. Do nothing when the vertex already exists.
  ///
  /// @return `true` if the vertex was added, `false` if it already existed.
  bool addVertex(V vertex) {
    if (_vertexIndexMap.containsKey(vertex)) {
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
  bool addEdge(V source, V target, GraphWeight weight) {
    if (weight < 0) return false;
    final sourceIndex = _vertexIndexMap[source];
    final targetIndex = _vertexIndexMap[target];
    if (sourceIndex == null || targetIndex == null) return false;

    _nodes[sourceIndex].adjacency[targetIndex] = weight;
    return true;
  }

  /// Add a bidirectional edge between [source] and [target] with the given [weight].
  /// The method is equivalent to calling [addEdge(source, target, weight)] and
  /// [addEdge(target, source, weight)].
  ///
  /// @warning The method adds edges even if they already exist, potentially creating duplicate edges.
  bool addBidirectionalEdge(V source, V target, GraphWeight weight) {
    if (weight < 0) return false;
    final sourceIndex = _vertexIndexMap[source];
    final targetIndex = _vertexIndexMap[target];
    if (sourceIndex == null || targetIndex == null) return false;

    _nodes[sourceIndex].adjacency[targetIndex] = weight;
    _nodes[targetIndex].adjacency[sourceIndex] = weight;
    return true;
  }

  /// Set the adjacency list for [vertex] with the given [edges].
  /// The method replaces any existing adjacency list for the vertex.
  ///
  /// @throws ArgumentError if [vertex] or any target vertex in [edges] does not exist.
  void setAdjacency(
    V vertex,
    Iterable<({V target, GraphWeight weight})> edges,
  ) {
    final vertexIndex = _vertexIndexMap[vertex];
    if (vertexIndex == null) throw ArgumentError('Unknown vertex.');

    _nodes[vertexIndex] = (
      key: vertex,
      adjacency: Map.fromEntries(
        edges.map((e) {
          final targetIndex = _vertexIndexMap[e.target];
          assert(targetIndex != null);

          return MapEntry(targetIndex!, e.weight);
        }),
      ),
    );
  }

  /// Create a graph that forgets the orientation.
  /// Hence, in the resulting graph, every edge is bidirectional in the sense that
  /// if $(u,v)$ is an edge with weight $a$, then $(v,u)$ is also an edge with
  /// the same weight $a$.
  /// If an edge is already bidirectional, the weights for the edge and its
  /// reverse edge are merged into a common value with `mergeOp`.
  ///
  /// @param mergeOp A function to merge the weights of edges that become bidirectional.
  /// @returns A new [Graph] instance with all edges made bidirectional.
  /// @warning Be aware that the order of weights passed to `mergeOp` is
  /// unspecified. Hence, it is always preferred that `mergeOp` is a commutative
  /// operation.
  Graph<V> disoriented(GraphWeight Function(GraphWeight, GraphWeight) mergeOp) {
    final newNodes = _nodes
        .map((node) => (key: node.key, adjacency: <int, GraphWeight>{}))
        .toList();

    for (int i = 0; i < _nodes.length; ++i) {
      for (final entry in _nodes[i].adjacency.entries) {
        final j = entry.key;
        final weight = entry.value;
        final invWeight = newNodes[i].adjacency[j];

        if (invWeight != null) {
          final newWeight = mergeOp(weight, invWeight);
          newNodes[i].adjacency[j] = newWeight;
          newNodes[j].adjacency[i] = newWeight;
        } else {
          newNodes[i].adjacency[j] = weight;
          newNodes[j].adjacency[i] = weight;
        }
      }
    }

    return Graph<V>._internal(newNodes, HashMap<V, int>.from(_vertexIndexMap));
  }

  List<GraphWeight> _dijkstraShortestPathImpl(int sourceIndex) {
    final n = _nodes.length;
    final d = List<GraphWeight>.filled(n, maxDistance);
    final visited = List<bool>.filled(n, false);
    final heap = _MinHeap.empty();

    d[sourceIndex] = 0;
    heap.insert(0, sourceIndex);

    while (!heap.isEmpty) {
      final current = heap.extractMin();

      if (visited[current.value]) continue;

      for (final edge in _nodes[current.value].adjacency.entries) {
        final next = edge.key;
        final weight = edge.value;
        final dNext = d[current.value] + weight;
        if (dNext < d[next]) {
          d[next] = dNext;
          heap.insert(dNext, next);
        }
      }

      visited[current.value] = true;
    }
    return d;
  }

  /// Compute the shortest path distances from the [source] vertex to all vertices.
  /// The method is implemented using Dijkstra's algorithm with a priority queue
  /// built on a simple binary heap.
  ///
  /// @returns A [HashMap] mapping each vertex to its shortest path distance from [source].
  /// @note If a vertex is unreachable from [source], its distance will be set to [maxDistance].
  HashMap<V, GraphWeight> dijkstraShortestPath(V source) {
    final sourceIndex = _vertexIndexMap[source];
    if (sourceIndex == null) return HashMap<V, GraphWeight>();

    final d = _dijkstraShortestPathImpl(sourceIndex);

    final result = HashMap<V, GraphWeight>.fromEntries(
      _vertexIndexMap.entries.map((e) => MapEntry(e.key, d[e.value])),
    );
    return result;
  }

  /// Compute a planar layout for the graph using a Kamada-Kawai algorithm.
  /// Only the positions of vertices present in [initialPositions] will be
  /// computed though the other vertices affects the overall layout.
  ///
  /// @param initialPositions A [HashMap] containing the initial positions of vertices.
  /// @param kk The strength of the spring.
  /// @param maxIterations The maximum number of iterations for the algorithm.
  /// If not specified, it will default to [initialPositions.length * 1000].
  /// @param tolerance The convergence tolerance for the algorithm. If not
  /// specified, it will default to 2^-22 (cf. ULP for 32bit floating-point
  /// numbers is 2^-23). Note that the tolerance is not always guaranteed when
  /// the algorithm may not converge to a solution in the required precision.
  /// @returns A [HashMap] mapping each vertex to its 2D position as a [GraphVertex].
  /// @warning If the graph is not strongly connected, the computation diverges
  /// and may not produce a valid layout.
  HashMap<V, GraphVertex> kamadaKawaiLayout(
    HashMap<V, GraphVertex> initialPositions, {
    required double kk,
    int? maxIterations,
    double tolerance = 1.0 / (1 << 26),
  }) {
    maxIterations ??= initialPositions.length * 100;

    final List<V> vertices = initialPositions.keys.toList(growable: false);
    final List<int> indices = vertices
        .map((v) => _vertexIndexMap[v]!)
        .toList(growable: false);

    // Compute all-pairs shortest path distances together with the graph diameter.
    double diameter = 0.0;
    final dist = List.generate(vertices.length, (i) {
      final sssp = _dijkstraShortestPathImpl(indices[i]);
      return List<double>.generate(vertices.length, (j) {
        final d = sssp[indices[j]].toDouble();
        if (d > diameter) diameter = d;
        return d;
      }, growable: false);
    }, growable: false);

    // If the graph is degenerated, return a copy of the initial positions.
    if (diameter < tolerance) {
      return HashMap.from(initialPositions);
    }

    // The threshold for considering the system to have reached equilibrium.
    final double threshold = diameter * tolerance;

    // The constant $L$ in the Kamada-Kawai original article.
    final ll = sqrt(vertices.length) / diameter;
    // The system of "springs" given by [Kamada-Kawai].
    final system = _KamadaKawaiSystem(dist, ll, kk);
    // Initialize vertex positions
    final List<GraphVertex> positions = List.generate(
      vertices.length,
      (i) => initialPositions[vertices[i]]!,
      growable: false,
    );

    // The following iteration tries to minimize the energy function of the
    // system of "springs" as described in the Kamada-Kawai layout algorithm.
    // Here, a *pointwise* Newton-Raphson method is applied to find the layout
    // on which the energy at the vertex experiencing the maximum force is
    // minimized.
    //
    // More precisely, each iteration step consists of the following:
    //
    // 1. Compute the energy and the force vectors applied to each vertex and
    //    find the vertex experiencing the maximum force.
    //    - Set `iMax` to the index of this vertex and `grad` the force vector.
    //    - If the size of `grad` (the force) doesn't exceed the maximum in the
    //      previous iteration (`maxDelta`), the system has reached equilibrium.
    //    - In this case, the iteration is terminated.
    // 2. Update the chosen vertex using the Newton-Raphson method until it
    //    sufficiently minimizes the energy at that vertex.
    //    - Compute the update vector $u$ as follows: it is obtained by scaling
    //      the negated gradient vector by $1/\lambda$ in the direction of
    //      each positive eigenvalue of the Hessian matrix.
    //      (Note that this operation is exactly equivalent to solving the
    //      linear system $H u = -\mathrm{grad}$ as in the ordinary Newton-Raphson
    //      method.)
    //    - Update `positions[iMax]` by adding the update vector $\alpha u$,
    //      where $\alpha$ is a step size parameter.
    //    - Re-compute the energy and the gradient at the chosen vertex.
    //    - Re-choose the step size parameter $\alpha$ until the Armijo
    //      condition is satisfied.
    //    - If the energy is not improved, this pointwise Newton-Raphson
    //      iteration has reached equilibrium, so the inner loop is terminated.
    //    - Otherwise, repeat the above inner loop.
    for (int itrCount = 0; itrCount < maxIterations; ++itrCount) {
      // Compute force vectors, and determine the vertex with the maximum force
      int iMax = 0;
      GraphVertex maxGrad = GraphVertex.zero();
      double maxDelta = 0.0;
      // The energy term for the vertex experiencing the maximum force.
      double maxEnergy = 0.0;
      double secondMaxDelta = 0.0;

      for (int i = 0; i < vertices.length; ++i) {
        final grad = GraphVertex.zero();
        final double e = system.energy(positions, i, grad);

        final delta = grad.length;

        if (delta > maxDelta) {
          iMax = i;
          maxGrad = grad;
          secondMaxDelta = maxDelta;
          maxDelta = delta;
          maxEnergy = e;
        } else if (delta > secondMaxDelta) {
          secondMaxDelta = delta;
        }
      }

      // Terminate the iteration when the positions reached around equilibrium.
      if (maxDelta < threshold) break;

      // Apply Newton-Raphson method to the chosen vertex
      while (true) {
        final (xx, xy, yy) = system.hessian(positions, iMax);

        final double det = xx * yy - xy * xy;
        final double trace = xx + yy;
        late final GraphVertex update;
        if (det > tolerance * tolerance && trace > tolerance) {
          // If the Hessian is positive definite, compute the update vector $u$ by
          // solving the linear system $Hu=-grad$.
          update = GraphVertex(
            (-yy * maxGrad.x + xy * maxGrad.y) / det,
            (xy * maxGrad.x - xx * maxGrad.y) / det,
          );
        } else if (det < -tolerance * tolerance || trace > tolerance) {
          // If only one of the eigen value of the Hessian is positive, we scale
          // the update vector along the direction of the positive eigenvalue.
          final discriminant = trace * trace - 4 * det;
          final eigenVal = (trace + sqrt(discriminant)) / 2;
          final eigenVec = GraphVertex(xy, eigenVal - xx).normalized();
          update =
              -maxGrad +
              eigenVec * (1.0 - 1.0 / eigenVal) * maxGrad.dot(eigenVec);
        } else {
          // Otherwise, just use the gradient vector.
          update = -maxGrad;
        }

        // Update the position by backtracking line search
        final oldPosition = positions[iMax].clone();
        double bound = (1.0 / (1 << 10)) * maxGrad.dot(update);
        final GraphVertex newGrad = GraphVertex.zero();
        late double newEnergy;

        for (int cnt = 0; cnt < 8; ++cnt) {
          // Update the position by the current update vector
          positions[iMax].setFrom(oldPosition + update);

          // Re-compute the energy and the gradient
          newGrad.setZero();
          newEnergy = system.energy(positions, iMax, newGrad);

          // If the update satisfies the Armijo condition, accept it.
          if (newEnergy < maxEnergy + bound) break;

          update.scale(0.5);
          bound /= 2;
        }

        final newDelta = newGrad.length;

        // If the update didn't improve the energy, rollback to the old position
        // and terminate the inner loop.
        //  - Furthermore, if the new gradient is not even smaller than the
        //    second maximum, then give up and terminate the outer loop as well.
        if (newEnergy >= maxEnergy) {
          if (kDebugMode) {
            print(
              'New energy ($newEnergy) did not improve over max energy ($maxEnergy).',
            );
          }
          positions[iMax] = oldPosition;
          if (newDelta >= secondMaxDelta) {
            itrCount = maxIterations;
          }
          break;
        }

        maxGrad = newGrad;
        maxDelta = newDelta;
        maxEnergy = newEnergy;

        // Terminate the inner loop if the gradient reaches below the tolerance.
        if (maxDelta < threshold) break;
      }

      if (itrCount + 1 >= maxIterations) {
        if (kDebugMode) {
          print(
            'The loop has reached the maximum number of iterations ($maxIterations).',
          );
        }
      }
    }

    return HashMap<V, GraphVertex>.fromIterables(vertices, positions);
  }
}

class _KamadaKawaiSystem {
  /// The table of the natural lengths of the springs between vertices.
  final List<List<double>> _springLengths;

  /// The table of the spring coefficients of the spring between vertices.
  final List<List<double>> _springCoeffs;

  _KamadaKawaiSystem(List<List<double>> weights, double ll, double kk)
    : _springLengths = List.generate(
        weights.length,
        (i) => List.generate(
          weights[i].length,
          (j) => ll * weights[i][j],
          growable: false,
        ),
        growable: false,
      ),
      _springCoeffs = List.generate(
        weights.length,
        (i) => List.generate(
          weights[i].length,
          (j) =>
              weights[i][j] == 0 ? 0.0 : kk / (weights[i][j] * weights[i][j]),
          growable: false,
        ),
        growable: false,
      );

  /// Compute the energy function of the system for the Kamada-Kawai layout
  /// algorithm at the [i]-th vertex in [positions] along with its gradient
  /// vector.
  /// The gradient vector will be added to [gradientOut].
  ///
  /// @returns The energy value at the [i]-th vertex.
  ///
  /// ### Note
  /// The value of the energy is actually twice of the its by-definition
  /// value. One needs to divide it by 2 to obtain the conventional energy value.
  double energy(List<GraphVertex> positions, int i, GraphVertex gradientOut) {
    final springLength = _springLengths[i];
    final springCoeff = _springCoeffs[i];

    double e = 0.0;
    for (int j = 0; j < positions.length; ++j) {
      if (i == j) continue;

      final diff = positions[i] - positions[j];
      final norm = diff.length;
      final delta = norm - springLength[j];

      e += springCoeff[j] * delta * delta;

      if (norm == 0.0) continue;

      diff.scale(springCoeff[j] * (1.0 - springLength[j] / norm));
      gradientOut.add(diff);
    }

    return e;
  }

  // Compute the Hessian matrix of the energy function of the system for the
  // Kamada-Kawai layout algorithm at the [i]-th vertex in [positions].
  //
  // @return A triple `(xx, xy, yy)` of the Hessian matrix components, where
  // [xx] and [yy] are the diagonal components, and [xy] is the (common)
  // off-diagonal.
  @pragma('vm:prefer-inline')
  @pragma('dart2js:tryInline')
  (double, double, double) hessian(List<GraphVertex> positions, int i) {
    // ULP for 64bit floating point numbers
    const double epsilon = 1.0 / (1 << 52);

    final springLength = _springLengths[i];
    final springCoeff = _springCoeffs[i];
    double xx = 0.0, xy = 0.0, yy = 0.0;
    for (int j = 0; j < positions.length; ++j) {
      if (j == i) continue;

      final diff = positions[i] - positions[j];
      final length1 = diff.length;
      final length3 = length1 * diff.length2;

      if (length1 < springLength[j] * epsilon) continue;

      xx +=
          springCoeff[j] * (1.0 - springLength[j] * diff.y * diff.y / length3);
      xy += springCoeff[j] * springLength[j] * diff.x * diff.y / length3;
      yy +=
          springCoeff[j] * (1.0 - springLength[j] * diff.x * diff.x / length3);
    }
    return (xx, xy, yy);
  }
}
