import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/core/graph.dart';
import 'package:monolingual/ui/graphview_widget.dart';

class SynonymView extends StatefulWidget {
  final Dictionary dictionary;
  final String word;
  final int searchDepth;
  final int visibleDepth;
  final void Function(String word)? onWordTapped;
  final double scale;

  const SynonymView({
    super.key,
    required this.dictionary,
    required this.word,
    required this.searchDepth,
    required this.visibleDepth,
    this.onWordTapped,
    this.scale = 20.0,
  });

  @override
  State<SynonymView> createState() => _SynonymViewState();
}

class _SynonymViewState extends State<SynonymView> {
  ({Graph<String> graph, HashMap<String, GraphVertex> positions})? _graphData;

  @override
  void initState() {
    super.initState();
    _buildGraph();
  }

  @override
  void didUpdateWidget(covariant SynonymView oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint(
      'didUpdateWidget: oldWord=${oldWidget.word}, newWord=${widget.word}',
    );
    debugPrint(
      'dictionary updated: ${oldWidget.dictionary != widget.dictionary}',
    );
    if (oldWidget.word != widget.word ||
        oldWidget.dictionary != widget.dictionary) {
      _buildGraph();
    }
  }

  Future<void> _buildGraph() async {
    setState(() => _graphData = null);

    final dictionary = widget.dictionary;
    final HashMap<String, int> depthMap = HashMap<String, int>();
    final Queue<({String word, int depth})> queue =
        Queue<({String word, int depth})>.from([(word: widget.word, depth: 0)]);
    final Graph<String> graph = Graph<String>(vertices: [widget.word]);

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      final word = current.word;
      final depth = current.depth;

      depthMap[word] = depth;

      final record = await dictionary.find(word);

      if (record == null) continue;

      for (final synonym in record.synonyms) {
        graph.addVertex(synonym);
        graph.addEdge(word, synonym, 2);

        if (depth < widget.searchDepth && !depthMap.containsKey(synonym)) {
          queue.add((word: synonym, depth: depth + 1));
        }
      }
    }

    // TODO: Change the algorithm to determine the initial positions of vertices:
    // 1. compute a spanning tree of the graph from the given word as the root
    //    with subtree node counting by the breadth-first traversal;
    // 2. divide the angle for branches proportionally based on the node count.
    // 3. assign initial positions to the vertices based on the computed angles
    //    and depths.
    final initialPos = HashMap<String, GraphVertex>();
    final phases = List<double>.generate(
      widget.visibleDepth + 1,
      (index) => index % pi,
    );
    final denoms = List<int>.filled(widget.visibleDepth + 1, 0);
    for (final d in depthMap.values) {
      if (d <= widget.visibleDepth) {
        denoms[d]++;
      }
    }
    for (final entry in depthMap.entries) {
      final word = entry.key;
      final depth = entry.value;
      if (depth > widget.visibleDepth) continue;

      final r = widget.scale * depth;
      final a = phases[depth];
      initialPos[word] = GraphVertex(r * cos(a), r * sin(a));
      phases[depth] += 2 * pi / denoms[depth];
    }

    // TODO: call `graph.kamadaKawaiLayout()` to compute the "good" layout.

    setState(() {
      _graphData = (graph: graph, positions: initialPos);
    });
  }

  @override
  Widget build(BuildContext context) {
    return _graphData == null
        ? const Center(child: CircularProgressIndicator())
        : GraphViewWidget(
            graph: _graphData!.graph,
            graphLayout: _graphData!.positions,
            vertexBuilder: (BuildContext context, String vertex) {
              return ActionChip(
                label: Text(vertex),
                padding: const EdgeInsets.all(0.0),
                side: const BorderSide(color: Colors.blue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                onPressed: widget.onWordTapped != null
                    ? (() => widget.onWordTapped!(vertex))
                    : null,
              );
            },
          );
  }
}
