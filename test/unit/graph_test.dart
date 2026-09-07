import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/graph.dart';
import 'package:vector_math/vector_math_64.dart';

// z-component of the 3-D cross product; 0 iff a ∥ b.
// double _cross2d(Vector2 a, Vector2 b) => a.x * b.y - a.y * b.x;

void main() {
  test('Dijkstra shortest path for Wikipedia example', () {
    final graph = Graph<String>(vertices: ['A', 'B', 'C', 'D', 'E', 'F']);
    graph.addBidirectionalEdge('A', 'B', 7);
    graph.addBidirectionalEdge('A', 'C', 9);
    graph.addBidirectionalEdge('A', 'F', 14);
    graph.addBidirectionalEdge('B', 'C', 10);
    graph.addBidirectionalEdge('B', 'D', 15);
    graph.addBidirectionalEdge('C', 'D', 11);
    graph.addBidirectionalEdge('C', 'F', 2);
    graph.addBidirectionalEdge('D', 'E', 6);
    graph.addBidirectionalEdge('E', 'F', 9);
    final result = graph.dijkstraShortestPath('A');
    expect(result['A'], 0);
    expect(result['B'], 7);
    expect(result['C'], 9);
    expect(result['D'], 20);
    expect(result['E'], 20);
    expect(result['F'], 11);
  });

  group('kamadaKawaiLayout', () {
    const kk = 1.0;
    const eps = (1.0 / (1 << 8));

    test('empty graph returns empty result', () {
      final graph = Graph<String>();
      final result = graph.kamadaKawaiLayout(HashMap(), kk: kk);
      expect(result, isEmpty);
    });

    test('single vertex position is unchanged', () {
      final graph = Graph<String>(vertices: ['A']);
      final init = HashMap<String, Vector2>.from({'A': Vector2(3.0, 7.0)});
      final result = graph.kamadaKawaiLayout(init, kk: kk);
      expect(result, equals(init));
    });

    // For a path graph the global minimum is E=0, achieved when vertices are
    // equally spaced along a line (every pair is at its exact spring length).
    test('path graph vertices are collinear with equal edge lengths', () {
      final graph = Graph<String>(vertices: ['P0', 'P1', 'P2', 'P3', 'P4']);
      graph.addBidirectionalEdge('P0', 'P1', 1);
      graph.addBidirectionalEdge('P1', 'P2', 1);
      graph.addBidirectionalEdge('P2', 'P3', 1);
      graph.addBidirectionalEdge('P3', 'P4', 1);

      final result = graph.kamadaKawaiLayout(
        HashMap.from({
          'P0': Vector2(0.5, 1.5),
          'P1': Vector2(2.0, 0.3),
          'P2': Vector2(1.0, 2.0),
          'P3': Vector2(3.5, 1.0),
          'P4': Vector2(2.5, 2.5),
        }),
        kk: kk,
      );

      final p = ['P0', 'P1', 'P2', 'P3', 'P4'].map((v) => result[v]!).toList();

      final v0 = p[1] - p[0];
      for (int i = 2; i < 5; i++) {
        final v = p[i] - p[0];
        expect((v - v0.scaled(i.toDouble())).length, closeTo(0.0, eps));
      }
    });

    // For a cycle graph the minimum is a regular n-gon (unique up to symmetry):
    // all vertices lie on a circle and all adjacent edges are equal.
    test('cycle graph vertices lie on a circle with equal edge lengths', () {
      final graph = Graph<String>(vertices: ['C0', 'C1', 'C2', 'C3', 'C4']);
      graph.addBidirectionalEdge('C0', 'C1', 1);
      graph.addBidirectionalEdge('C1', 'C2', 1);
      graph.addBidirectionalEdge('C2', 'C3', 1);
      graph.addBidirectionalEdge('C3', 'C4', 1);
      graph.addBidirectionalEdge('C4', 'C0', 1);

      final result = graph.kamadaKawaiLayout(
        HashMap.from({
          'C0': Vector2(1.5, 0.1),
          'C1': Vector2(0.6, 1.4),
          'C2': Vector2(-1.0, 0.9),
          'C3': Vector2(-0.7, -0.9),
          'C4': Vector2(0.4, -1.2),
        }),
        kk: kk,
      );

      final positions = [
        'C0',
        'C1',
        'C2',
        'C3',
        'C4',
      ].map((v) => result[v]!).toList();

      final cx = positions.fold(0.0, (s, p) => s + p.x) / 5;
      final cy = positions.fold(0.0, (s, p) => s + p.y) / 5;
      final centroid = Vector2(cx, cy);

      final radii = positions.map((p) => (p - centroid).length).toList();
      for (final r in radii) {
        expect(r, closeTo(radii[0], eps));
      }

      final edges = [
        (result['C1']! - result['C0']!).length,
        (result['C2']! - result['C1']!).length,
        (result['C3']! - result['C2']!).length,
        (result['C4']! - result['C3']!).length,
        (result['C0']! - result['C4']!).length,
      ];
      for (final d in edges) {
        expect(d, closeTo(edges[0], eps));
      }
    });
  });
}
