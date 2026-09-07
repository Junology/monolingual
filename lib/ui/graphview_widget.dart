import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:monolingual/core/graph.dart';

class GraphViewWidget<V> extends LeafRenderObjectWidget {
  final Graph<V> graph;
  final HashMap<V, Vector2> graphLayout;

  const GraphViewWidget({
    super.key,
    required this.graph,
    required this.graphLayout,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphRenderObject<V>(graph: graph, graphLayout: graphLayout);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant GraphRenderObject<V> renderObject,
  ) {
    renderObject
      ..graph = graph
      ..graphLayout = graphLayout;
  }
}

class GraphRenderObject<V> extends RenderBox {
  Graph<V> _graph;
  HashMap<V, Vector2> _graphLayout;

  Graph<V> get graph => _graph;
  set graph(Graph<V> value) {
    if (value == _graph) return;
    _graph = value;
    markNeedsLayout();
  }

  HashMap<V, Vector2> get graphLayout => _graphLayout;
  set graphLayout(HashMap<V, Vector2> value) {
    if (value == _graphLayout) return;
    _graphLayout = value;
    markNeedsLayout();
  }

  GraphRenderObject({required this._graph, required this._graphLayout});

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final Canvas canvas = context.canvas;
    canvas.clipRect(offset & size, doAntiAlias: false);
    for (final pos in _graphLayout.values) {
      // Draw the vertex at the given position.
      canvas.drawCircle(
        Offset(pos.x, pos.y) + size.center(offset),
        5.0,
        Paint()..color = Colors.blue,
      );
    }
  }
}
