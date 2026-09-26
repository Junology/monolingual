import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart' hide Stack;
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/core/sumtree.dart';
import 'package:monolingual/core/graph.dart';
import 'package:monolingual/ui/graphview_widget.dart';

/// Helper class
extension _ColorHelper on Color {
  /// Returns a lighter version of this color by the given [factor].
  /// [factor]: A value between `0.0` (no change) and `1.0` (full lightness).
  Color lighter(double factor) {
    final hsl = HSLColor.fromColor(this);
    final lightness = hsl.lightness;
    return hsl.withLightness(lightness + (1.0 - lightness) * factor).toColor();
  }

  /// Returns a darker version of this color by the given [factor].
  /// [factor]: A value between `0.0` (no change) and `1.0` (full darkness).
  // ignore: unused_element
  Color darker(double factor) {
    final hsl = HSLColor.fromColor(this);
    final lightness = hsl.lightness;
    return hsl.withLightness(lightness * (1.0 - factor)).toColor();
  }
}

/// Widget that visually displays the arrangement of synonyms for a given word
/// in the dictionary.
class SynonymView extends StatefulWidget {
  final Dictionary dictionary;
  final String word;
  final int searchDepth;
  final int visibleDepth;
  final Widget Function(String word)? labelBuilder;
  final void Function(String word)? onWordTapped;
  final double scale;

  const SynonymView({
    super.key,
    required this.dictionary,
    required this.word,
    required this.searchDepth,
    required this.visibleDepth,
    this.labelBuilder,
    this.onWordTapped,
    this.scale = 20.0,
  });

  @override
  State<SynonymView> createState() => _SynonymViewState();
}

class _SynonymViewState extends State<SynonymView> {
  ({
    Graph<String> graph,
    HashMap<String, GraphVertex> positions,
    HashMap<String, int> depths,
  })?
  _graphData;
  late Widget Function(String word) _labelBuilder;

  @override
  void initState() {
    super.initState();
    _labelBuilder = widget.labelBuilder ?? (word) => Text(word);
    _buildGraph();
  }

  @override
  void didUpdateWidget(covariant SynonymView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.labelBuilder != widget.labelBuilder) {
      _labelBuilder = widget.labelBuilder ?? (word) => Text(word);
    }
    if (oldWidget.word != widget.word ||
        oldWidget.dictionary != widget.dictionary) {
      _buildGraph();
    }
  }

  Future<void> _buildGraph() async {
    setState(() => _graphData = null);

    final dictionary = widget.dictionary;

    // Create a graph of synonyms starting from the given word as the root.
    // The graph is constructed using a breadth-first traversal up to the
    // specified search depth.
    // Besides constructing the graph, the spanning-tree which tracks the
    // breadth-first traversal is also constructed using [SumTreeNode] to
    // count the number of nodes in each subtree.

    // Target data
    final HashMap<String, int> depthMap = HashMap<String, int>();
    final SumTreeNode<String> root = SumTreeNode<String>(widget.word, 1);
    final Graph<String> graph = Graph<String>(vertices: [widget.word]);

    // Queue for breadth-first traversal
    final Queue<({String word, int depth, SumTreeNode<String> node})> queue =
        Queue<({String word, int depth, SumTreeNode<String> node})>.from([
          (word: widget.word, depth: 0, node: root),
        ]);

    // Breadth-first traversal
    while (queue.isNotEmpty) {
      final (:word, :depth, :node) = queue.removeFirst();

      depthMap[word] = depth;

      if (depth >= widget.searchDepth) continue;

      final record = await dictionary.find(word);

      if (record == null) continue;

      for (final synonym in record.synonyms) {
        graph.addVertex(synonym);
        graph.addEdge(word, synonym, 2);

        if (!depthMap.containsKey(synonym)) {
          depthMap[synonym] = depth + 1;
          queue.add((
            word: synonym,
            depth: depth + 1,
            node: node.createChild(synonym, 1),
          ));
        }
      }
    }

    // Generate initial positions [GraphVertex] for the vertices based on their
    // depth and the size of the subtree in the spanning tree [root] created
    // in the previous breadth-first traversal (see above).

    // target data
    final initialPos = HashMap<String, GraphVertex>();

    // Stack for depth-first traversal in the spanning tree
    List<({SumTreeNode<String> node, int depth, double start, double end})>
    stack = [(node: root, depth: 0, start: 0, end: 2 * pi)];

    // Depth-first traversal to assign initial positions to the vertices in the
    // spanning tree of depth up to `widget.visibleDepth`.
    // The algorithm works as follows:
    // 1. divide the angle for branches proportionally based on the size of the
    //    subtree.
    // 2. assign initial positions to the vertices based on the computed angles
    //    and depths.
    while (stack.isNotEmpty) {
      final (:node, :depth, :start, :end) = stack.removeLast();

      // The angle for the current vertex
      // The last term is a perturbation in order to make sure the vertices
      // are in "general position".
      // Thus, it should not be a rational multiple of pi.
      final angle = (start + end) / 2 + (0.125 * depth / widget.visibleDepth);

      // The radius of the current vertex based on its depth.
      // Since we scale the whole vertices later, we don't have [widget.scale]
      // here.
      final r = depth.toDouble();

      // Assign the computed position to the current vertex.
      initialPos[node.value] = GraphVertex(r * cos(angle), r * sin(angle));

      // Descend to the children if the current depth is less than the specified
      // depth.
      if (depth >= widget.visibleDepth) continue;
      final delta = (end - start) / (node.sum - 1);
      double childAngle = start;
      for (final child in node.children) {
        final childEnd = childAngle + delta * child.sum;
        stack.add((
          node: child,
          depth: depth + 1,
          start: childAngle,
          end: childEnd,
        ));
        childAngle = childEnd;
      }
    }

    // Compute the layout of the graph using the Kamada-Kawai algorithm.
    final graphLayout = graph
        .disoriented((x, y) => (x + y) ~/ 4)
        .kamadaKawaiLayout(initialPos, kk: 10.0);

    // TODO: apply in addition the Fruchterman-Reingold algorithm to improve the layout, in particular, to avoid overlapping vertices.

    final basePos = graphLayout[widget.word]!;
    graphLayout.updateAll((_, v) => (v - basePos).scaled(widget.scale));

    setState(() {
      _graphData = (graph: graph, positions: graphLayout, depths: depthMap);
    });
  }

  @override
  Widget build(BuildContext context) {
    const List<Color> depthColors = <Color>[
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
    ];
    return _graphData == null
        ? const Center(child: CircularProgressIndicator())
        : GraphViewWidget(
            graph: _graphData!.graph,
            graphLayout: _graphData!.positions,
            edgeColor: Colors.indigo.shade400.withAlpha(128),
            vertexBuilder: (BuildContext context, String vertex) {
              final depth = _graphData!.depths[vertex] ?? 0;
              final color = depthColors[depth % depthColors.length];
              return Opacity(
                opacity: pow(0.78, depth).toDouble(),
                child: ActionChip(
                  label: _labelBuilder(vertex),
                  padding: const EdgeInsets.all(0.0),
                  side: BorderSide(color: color, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  backgroundColor: color.lighter(0.6),
                  onPressed: widget.onWordTapped != null
                      ? (() => widget.onWordTapped!(vertex))
                      : null,
                ),
              );
            },
          );
  }
}
