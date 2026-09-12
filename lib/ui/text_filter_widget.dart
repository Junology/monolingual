import 'package:flutter/material.dart';

enum SearchMode {
  prefix,
  wildcard,
  regex;

  String makeRegExpPattern(String query) => switch (this) {
    SearchMode.prefix => '^${RegExp.escape(query)}.*',
    SearchMode.wildcard =>
      '^${query.replaceAll('.', '\\.').replaceAll('+', '\\+').replaceAll('^', '\\^').replaceAll('\$', '\\\$').replaceAll('|', '\\|').replaceAll('(', '\\(').replaceAll(')', '\\)').replaceAll('[', '\\[').replaceAll(']', '\\]').replaceAll('{', '\\{').replaceAll('}', '\\}').replaceAll(RegExp(r'(?<!\\)\*'), '.*').replaceAll(RegExp(r'(?<!\\)\?'), '.')}\$',
    SearchMode.regex => query,
  };
}

class TextFilterWidget extends StatefulWidget {
  final List<String> items;
  final SearchMode searchMode;
  final ValueNotifier<Iterable<String>>? filteredItemsNotifier;
  final FocusNode? focusNode;
  final VoidCallback? onSubmitted;
  final bool autoFocus;

  const TextFilterWidget({
    super.key,
    required this.items,
    required this.searchMode,
    this.filteredItemsNotifier,
    this.focusNode,
    this.onSubmitted,
    this.autoFocus = false,
  });

  @override
  State<TextFilterWidget> createState() => _TextFilterWidgetState();
}

class _TextFilterWidgetState extends State<TextFilterWidget> {
  late ValueNotifier<Iterable<String>> _filteredItemsNotifier;
  late FocusNode _focusNode;
  late TextEditingController _textEditingController;
  bool _validInput = true;

  @override
  void initState() {
    super.initState();
    _filteredItemsNotifier =
        widget.filteredItemsNotifier ?? ValueNotifier(widget.items);
    _focusNode = widget.focusNode ?? FocusNode();
    _textEditingController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant TextFilterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filteredItemsNotifier != oldWidget.filteredItemsNotifier) {
      final oldValue = _filteredItemsNotifier.value;
      if (widget.filteredItemsNotifier == null) {
        _filteredItemsNotifier.dispose();
      }
      _filteredItemsNotifier =
          widget.filteredItemsNotifier ?? ValueNotifier(widget.items);
      _filteredItemsNotifier.value = oldValue;
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.filteredItemsNotifier == null) {
      _filteredItemsNotifier.dispose();
    }
    super.dispose();
  }

  Iterable<String> _filterItems(String query) {
    final pattern = widget.searchMode.makeRegExpPattern(query);
    return widget.items.where((item) {
      try {
        final regex = RegExp(pattern, unicode: true);
        if (!_validInput) {
          setState(() => _validInput = true);
        }
        return regex.hasMatch(item);
      } catch (_) {
        if (_validInput) {
          setState(() => _validInput = false);
        }
        return false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      focusNode: _focusNode,
      textEditingController: _textEditingController,
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return const Iterable<String>.empty();
        }
        return _filterItems(textEditingValue.text);
      },
      onSelected: (String item) =>
          setState(() => _filteredItemsNotifier.value = [item]),
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onFieldSubmitted,
          ) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              autofocus: widget.autoFocus,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                error: _validInput
                    ? null
                    : const Icon(Icons.error, size: 16, color: Colors.red),
              ),
              onSubmitted: (String value) {
                _filteredItemsNotifier.value = _filterItems(value);
                widget.onSubmitted?.call();
              },
              onChanged: (String value) =>
                  _filteredItemsNotifier.value = _filterItems(value),
            );
          },
    );
  }
}
