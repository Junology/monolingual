import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:monolingual/core/graph.dart';

/// A widget to render a [Graph] with child widgets on each vertex.
/// Only vertices with coordinates specified in the [graphLayout] will be rendered.
class GraphViewWidget<V> extends RenderObjectWidget {
  final Graph<V> _graph;
  final HashMap<V, GraphVertex> _graphLayout;
  final Widget Function(BuildContext context, V vertex) _vertexBuilder;

  const GraphViewWidget({
    super.key,
    required this._graph,
    required this._graphLayout,
    required this._vertexBuilder,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return GraphRenderObject<V>(graph: _graph, graphLayout: _graphLayout);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant GraphRenderObject<V> renderObject,
  ) {
    renderObject
      ..graph = _graph
      ..graphLayout = _graphLayout;
  }

  @override
  GraphViewElement<V> createElement() => GraphViewElement<V>(this);
}

/// The element corresponding to a [GraphViewWidget].
/// The class is mostly the same as [SlottedRenderObjectElement] except that it
/// creates child elements using builders instead of directly from widgets.
class GraphViewElement<V> extends RenderObjectElement {
  GraphViewElement(GraphViewWidget super.widget);

  /// A mapping associating each vertex with its corresponding child element, if any.
  HashMap<V, Element> _slotToChild = HashMap<V, Element>();

  /// A subset of [_slotToChild] consisting of child elements for [Widget]s with [Key]s.
  Map<Key, Element> _keyedChildren = {};

  @override
  GraphViewWidget<V> get widget => super.widget as GraphViewWidget<V>;

  @override
  GraphRenderObject<V> get renderObject =>
      super.renderObject as GraphRenderObject<V>;

  @override
  void visitChildren(ElementVisitor visitor) {
    _slotToChild.values.forEach(visitor);
  }

  @override
  void forgetChild(Element child) {
    assert(_slotToChild.containsValue(child));
    assert(child.slot is V);
    assert(_slotToChild.containsKey(child.slot));
    _slotToChild.removeWhere((_, element) => element == child);
    super.forgetChild(child);
  }

  @override
  void mount(Element? parent, Object? newSlot) {
    super.mount(parent, newSlot);
    _updateChildren();
  }

  @override
  void update(covariant GraphViewWidget<V> newWidget) {
    super.update(newWidget);
    assert(widget == newWidget);
    _updateChildren();
  }

  @override
  void performRebuild() {
    super.performRebuild();
    _updateChildren();
  }

  void _updateChildren() {
    final oldSlotToChildren = _slotToChild;
    _slotToChild = HashMap<V, Element>();
    final oldKeyedElements = _keyedChildren;
    _keyedChildren = {};
    for (final vertex in widget._graphLayout.keys) {
      final built = widget._graph.containsVertex(vertex)
          ? widget._vertexBuilder(this, vertex)
          : null;
      final newWidgetKey = built?.key;

      final oldSlotChild = oldSlotToChildren[vertex];
      final oldKeyedChild = newWidgetKey != null
          ? oldKeyedElements[newWidgetKey]
          : null;

      final Element? fromElement;
      if (oldKeyedChild != null) {
        fromElement = oldSlotToChildren.remove(oldKeyedChild.slot as V);
      } else if (oldSlotChild != null) {
        fromElement = oldSlotToChildren.remove(vertex);
      } else {
        fromElement = null;
      }
      final newChild = updateChild(fromElement, built, vertex);

      if (newChild != null) {
        _slotToChild[vertex] = newChild;

        if (newWidgetKey != null) {
          _keyedChildren[newWidgetKey] = newChild;
        }
      }
    }
    oldSlotToChildren.values.forEach(deactivateChild);
  }

  @override
  void insertRenderObjectChild(RenderBox child, V slot) {
    renderObject._setChild(child, slot);
    assert(
      renderObject._slotToChild[slot] == child,
      'Child for slot $slot was not correctly inserted.',
    );
  }

  @override
  void removeRenderObjectChild(RenderBox child, V slot) {
    if (renderObject._slotToChild[slot] == child) {
      renderObject._setChild(null, slot);
      assert(
        renderObject._slotToChild[slot] == null,
        'Child for slot $slot was not correctly removed.',
      );
    }
  }

  @override
  void moveRenderObjectChild(RenderBox child, V oldSlot, V newSlot) {
    renderObject._moveChild(child, newSlot, oldSlot);
  }
}

/// RenderObject corresponding to [GraphViewWidget].
class GraphRenderObject<V> extends RenderBox {
  Graph<V> _graph;
  HashMap<V, GraphVertex> _graphLayout;
  final HashMap<V, RenderObject> _slotToChild = HashMap<V, RenderObject>();

  Iterable<V> get slots => _slotToChild.keys;
  Iterable<RenderObject> get children => _slotToChild.values;

  RenderObject? childForSlot(V? slot) => _slotToChild[slot];

  Graph<V> get graph => _graph;
  set graph(Graph<V> value) {
    if (value == _graph) return;
    _graph = value;
    markNeedsLayout();
  }

  HashMap<V, GraphVertex> get graphLayout => _graphLayout;
  set graphLayout(HashMap<V, GraphVertex> value) {
    if (value == _graphLayout) return;
    _graphLayout = value;
    markNeedsLayout();
  }

  GraphRenderObject({required this._graph, required this._graphLayout});

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    for (final child in _slotToChild.values) {
      child.attach(owner);
    }
  }

  @override
  void detach() {
    super.detach();
    for (final child in _slotToChild.values) {
      child.detach();
    }
  }

  @override
  void redepthChildren() => _slotToChild.values.forEach(redepthChild);

  @override
  void visitChildren(RenderObjectVisitor visitor) =>
      _slotToChild.values.forEach(visitor);

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    return constraints.biggest;
  }

  @override
  void performLayout() {
    // size = constraints.biggest;
    for (final entry in _slotToChild.entries) {
      final child = entry.value as RenderBox;
      final slot = entry.key;
      child.layout(const BoxConstraints(), parentUsesSize: true);
      final childOffset = child.parentData! as BoxParentData;
      childOffset.offset = _getChildOffset(slot);
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    const Color arrowColor = Color(0x80000000);
    const Color vertexColor = Color(0xFF8080FF);
    final Canvas canvas = context.canvas;
    canvas.clipRect(offset & size, doAntiAlias: false);
    for (final edge in _graph.edges) {
      final sourcePos = _graphLayout[edge.source];
      final targetPos = _graphLayout[edge.target];

      if (sourcePos == null || targetPos == null) continue;

      canvas.drawLine(
        Offset(sourcePos.x, sourcePos.y) + size.center(offset),
        Offset(targetPos.x, targetPos.y) + size.center(offset),
        Paint()
          ..color = arrowColor
          ..strokeWidth = 2.0,
      );
    }

    // Render the vertices and the edges
    for (final entry in _slotToChild.entries) {
      final slot = entry.key;
      final pos = _graphLayout[slot]!;
      canvas.drawCircle(
        Offset(pos.x, pos.y) + size.center(offset),
        5.0,
        Paint()
          ..color = vertexColor
          ..style = PaintingStyle.fill,
      );
    }
    // Render the child widgets on top of the vertices
    for (final entry in _slotToChild.entries) {
      final child = entry.value as RenderBox;
      final childParentData = child.parentData! as BoxParentData;
      context.paintChild(child, offset + childParentData.offset);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (final entry in _slotToChild.entries) {
      final child = entry.value as RenderBox;
      final childParentData = child.parentData! as BoxParentData;
      final childOffset = childParentData.offset;
      if (result.addWithPaintOffset(
        offset: childOffset,
        position: position,
        hitTest: (result, transformed) {
          return child.hitTest(result, position: transformed);
        },
      )) {
        return true;
      }
    }
    return false;
  }

  @override
  bool hitTestSelf(Offset position) => size.contains(position);

  void _setChild(RenderBox? child, V slot) {
    final oldChild = _slotToChild[slot];
    if (oldChild != null) {
      dropChild(oldChild);
      _slotToChild.remove(slot);
    }
    if (child != null && _graphLayout.containsKey(slot)) {
      _slotToChild[slot] = child;
      adoptChild(child);
    } else if (kDebugMode) {
      debugPrint(
        'Child for slot `$slot` was not added because the slot is not in the graph layout.',
      );
      debugPrint('Current graph layout keys: ${_graphLayout.keys.toList()}');
    }
  }

  void _moveChild(RenderBox child, V slot, V oldSlot) {
    assert(slot != oldSlot);
    final oldChild = _slotToChild[oldSlot];
    if (oldChild == child) {
      _setChild(null, oldSlot);
    }
    _setChild(child, slot);
  }

  Offset _getChildOffset(V slot) {
    final child = _slotToChild[slot] as RenderBox;
    final vertexPos = _graphLayout[slot];

    if (vertexPos == null) {
      if (kDebugMode) {
        debugPrint('Vertex position for slot `$slot` is not specified.');
      }
      return Offset.zero;
    }

    final childSize = child.size;
    return Offset(
      vertexPos.x + size.width / 2 - childSize.width / 2,
      vertexPos.y + size.height / 2 - childSize.height / 2,
    );
  }
}
