import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/graph.dart';

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
}
