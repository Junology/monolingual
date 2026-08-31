import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

class WordInputField extends StatefulWidget {
  final Map<String, Iterable<String> Function(String)> wordIndexMap;
  final bool showDictionaryName;
  final TextEditingController? textEditingController;
  final FocusNode? focusNode;
  final void Function(String word, String? dictionaryName)? onSubmitted;
  final bool autofocus;

  const WordInputField({
    super.key,
    required this.wordIndexMap,
    this.showDictionaryName = false,
    this.textEditingController,
    this.focusNode,
    this.onSubmitted,
    this.autofocus = false,
  });

  @override
  State<WordInputField> createState() => _WordInputFieldState();
}

class _WordInputFieldState extends State<WordInputField> {
  String? _selectedDictionaryName;
  late FocusNode _focusNode;
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _textEditingController =
        widget.textEditingController ?? TextEditingController();
  }

  @override
  void didUpdateWidget(covariant WordInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.dispose();
      }
      _focusNode = widget.focusNode ?? FocusNode();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.textEditingController == null) {
      _textEditingController.dispose();
    }
    super.dispose();
  }

  Widget? _buildDictionaryNameSuffix(
    BuildContext context, [
    String? dictionaryName,
  ]) {
    dictionaryName ??= _selectedDictionaryName;
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

        var words = widget.wordIndexMap.entries.expand(
          (entry) => entry.value(text).map((word) => MapEntry(entry.key, word)),
        );
        return words.sorted((a, b) {
          int cmp = a.value.compareTo(b.value);
          return cmp != 0 ? cmp : a.key.compareTo(b.key);
        });
      },
      displayStringForOption: (option) => option.value,
      onSelected: (option) =>
          setState(() => _selectedDictionaryName = option.key),
      fieldViewBuilder:
          (context, textEditingController, focusNode, onSubmitted) {
            return TextField(
              controller: textEditingController,
              focusNode: focusNode,
              autofocus: widget.autofocus,
              onChanged: (value) {
                setState(() => _selectedDictionaryName = null);
              },
              onSubmitted: (value) {
                onSubmitted();
                widget.onSubmitted?.call(value, _selectedDictionaryName);
              },
              decoration: InputDecoration(
                suffix: _buildDictionaryNameSuffix(context),
              ),
            );
          },
      optionsViewBuilder: (context, onSelected, options) {
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

class WordInputDialog extends StatelessWidget {
  final Iterable<String> Function(String)? wordIndex;
  final String initialValue;
  final void Function(String)? onSubmitted;
  final void Function()? onCancelled;

  final TextEditingController _controller = TextEditingController();

  WordInputDialog({
    super.key,
    this.wordIndex,
    this.initialValue = '',
    this.onSubmitted,
    this.onCancelled,
  });

  void _onSubmit(BuildContext context, String value) {
    onSubmitted?.call(value);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: WordInputField(
        textEditingController: _controller,
        wordIndexMap: wordIndex != null
            ? {'default': (input) => wordIndex!(input)}
            : {},
        showDictionaryName: false,
        onSubmitted: (word, _) => _onSubmit(context, word),
        autofocus: true,
      ),
      actions: [
        IconButton(
          onPressed: () {
            onCancelled?.call();
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.cancel, color: Colors.red),
        ),
        IconButton(
          onPressed: () => _onSubmit(context, _controller.text),
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
      ],
    );
  }
}
