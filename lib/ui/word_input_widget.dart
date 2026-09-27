import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class WordInputField extends StatefulWidget {
  final Map<String, Iterable<String> Function(String)> wordIndexMap;
  final bool showDictionaryName;
  final TextEditingController? textEditingController;
  final ValueNotifier<String?>? dictionaryNameNotifier;
  final FocusNode? focusNode;
  final void Function(String word, String? dictionaryName)? onSubmitted;
  final bool autofocus;
  final InputDecoration? inputDecoration;

  const WordInputField({
    super.key,
    required this.wordIndexMap,
    this.showDictionaryName = false,
    this.textEditingController,
    this.dictionaryNameNotifier,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
    this.inputDecoration = const InputDecoration(
      fillColor: Colors.white,
      filled: true,
      border: OutlineInputBorder(),
    ),
  });

  @override
  State<WordInputField> createState() => _WordInputFieldState();
}

class _WordInputFieldState extends State<WordInputField> {
  late TextEditingController _textEditingController;
  late ValueNotifier<String?> _dictionaryNameNotifier;
  late FocusNode _focusNode;
  late InputDecoration? _inputDecoration;

  late Map<String, Iterable<String> Function(String)> _wordIndexMap;

  @override
  void initState() {
    super.initState();
    _textEditingController =
        widget.textEditingController ?? TextEditingController();
    _dictionaryNameNotifier =
        widget.dictionaryNameNotifier ?? ValueNotifier<String?>(null);
    _focusNode = widget.focusNode ?? FocusNode();
    _wordIndexMap = Map<String, Iterable<String> Function(String)>.from(
      widget.wordIndexMap,
    );
    _inputDecoration = widget.inputDecoration;
  }

  @override
  void didUpdateWidget(covariant WordInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.textEditingController != oldWidget.textEditingController) {
      if (oldWidget.textEditingController == null) {
        _textEditingController.dispose();
      }
      _textEditingController =
          widget.textEditingController ?? TextEditingController();
    }
    if (widget.dictionaryNameNotifier != oldWidget.dictionaryNameNotifier) {
      if (oldWidget.dictionaryNameNotifier == null) {
        _dictionaryNameNotifier.dispose();
      }
      _dictionaryNameNotifier =
          widget.dictionaryNameNotifier ?? ValueNotifier<String?>(null);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
    if (widget.inputDecoration != oldWidget.inputDecoration) {
      _inputDecoration = widget.inputDecoration;
    }
    // TODO: Detect change of [wordIndexMap] properly
    const mapEquality = MapEquality();
    if (!mapEquality.equals(widget.wordIndexMap, oldWidget.wordIndexMap)) {
      _wordIndexMap = Map<String, Iterable<String> Function(String)>.from(
        widget.wordIndexMap,
      );
      _updateDictionaryName();
      // Force `RawAutocomplete` to rebuild options
      _refreshAutocompleteOptions();
    }
  }

  @override
  void dispose() {
    if (widget.textEditingController == null) {
      _textEditingController.dispose();
    }
    if (widget.dictionaryNameNotifier == null) {
      _dictionaryNameNotifier.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  /// Force `RawAutocomplete` to rebuild options
  /// This method is needed since the current implementation of `RawAutocomplete`
  /// does not automatically rebuild its options when the underlying data changes.
  ///
  /// Related issue and PR:
  /// - https://github.com/flutter/flutter/issues/159443
  /// - https://github.com/flutter/flutter/pull/190686
  ///
  /// TODO: Remove [WordInputField._refreshAutocompleteOptions] once `RawAutocomplete` properly rebuilds its options.
  void _refreshAutocompleteOptions() {
    if (_textEditingController.text.isEmpty) return;

    final aux = _textEditingController.value;
    _textEditingController.value = aux.copyWith(
      text: '${aux.text}\u200B', // add the zero-width space
      selection: TextSelection.collapsed(offset: aux.text.length + 1),
    );
    //_textEditingController.value = aux;
    _textEditingController.value = aux.copyWith(
      selection: TextSelection.collapsed(offset: aux.text.length),
    );
  }

  void _updateDictionaryName([String? word]) {
    word ??= _textEditingController.text;
    final current = _dictionaryNameNotifier.value;

    // The current word is in the dictionary.
    // In this case, we don't need to update the dictionary name.
    if (current != null &&
        _wordIndexMap[current]?.call(word).firstOrNull == word) {
      return;
    }

    // Otherwise, guess a dictionary of the current word.
    // Namely, if there is a unique dictionary that contains the word, then it
    // is the one.
    // If there are none or multiple, then set the dictionary name to `null`.
    final guess = _wordIndexMap.entries
        .where((element) => element.value(word!).firstOrNull == word)
        .singleOrNull;
    if (guess != null) {
      setState(() => _dictionaryNameNotifier.value = guess.key);
    } else {
      setState(() => _dictionaryNameNotifier.value = null);
    }
  }

  Widget? _buildDictionaryNameSuffix(
    BuildContext context, [
    String? dictionaryName,
  ]) {
    dictionaryName ??= _dictionaryNameNotifier.value;
    if (!widget.showDictionaryName || dictionaryName == null) {
      return null;
    }
    return Text(
      '($dictionaryName)',
      style: Theme.of(context).textTheme.labelSmall?.apply(color: Colors.grey),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<MapEntry<String, String>>(
      focusNode: _focusNode,
      textEditingController: _textEditingController,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final text = textEditingValue.text;
        final selection = textEditingValue.selection;

        // Input suggestions are only provided
        //  - when the input is non-empty,
        //  - when there is no composition of text in progress, and
        //  - when there is no selection of text.
        if (text.isEmpty ||
            textEditingValue.composing.isValid ||
            !selection.isCollapsed) {
          return const Iterable<MapEntry<String, String>>.empty();
        }

        final words = _wordIndexMap.entries.expand(
          (entry) => entry.value(text).map((word) => MapEntry(entry.key, word)),
        );

        return words.sorted((a, b) {
          int cmp = a.value.compareTo(b.value);
          return cmp != 0 ? cmp : a.key.compareTo(b.key);
        });
      },
      displayStringForOption: (option) => option.value,
      onSelected: (option) =>
          setState(() => _dictionaryNameNotifier.value = option.key),
      fieldViewBuilder:
          (
            BuildContext context,
            TextEditingController textEditingController,
            FocusNode focusNode,
            VoidCallback onSubmitted,
          ) {
            final dictionaryName = _dictionaryNameNotifier.value;
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              onChanged: (value) => _updateDictionaryName(value),
              onSubmitted: (value) {
                onSubmitted();
                if (dictionaryName != null) {
                  widget.onSubmitted?.call(value, dictionaryName);
                }
              },
              decoration: _inputDecoration?.copyWith(
                suffix: _buildDictionaryNameSuffix(context, dictionaryName),
              ),
              enabled: _wordIndexMap.isNotEmpty,
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
        // Get the index of the currently highlighted option.
        int highlightedOptionIndex = AutocompleteHighlightedOption.of(context);
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    title: Text(option.value),
                    trailing: _buildDictionaryNameSuffix(context, option.key),
                    selected: index == highlightedOptionIndex,
                    selectedTileColor: Theme.of(context).highlightColor,
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
