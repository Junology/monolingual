import 'package:flutter/material.dart';
import 'package:monolingual/ui/word_input_widget.dart';

/// A common dialog with a content widget and nonverbal confirm/cancel buttons.
class CommonConfirmDialog extends StatelessWidget {
  final Widget content;
  final void Function()? onConfirmed;
  final void Function()? onCancelled;

  const CommonConfirmDialog({
    super.key,
    required this.content,
    this.onConfirmed,
    this.onCancelled,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: content,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            onCancelled?.call();
          },
          icon: const Icon(Icons.cancel, color: Colors.red),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirmed?.call();
          },
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
      ],
    );
  }
}

/// Dialog for generic text input.
class TextInputDialog extends StatefulWidget {
  final String initialValue;
  final bool isMultiline;
  final void Function(String)? onSubmitted;
  final void Function()? onCancelled;

  const TextInputDialog({
    super.key,
    this.initialValue = '',
    this.onSubmitted,
    this.onCancelled,
    this.isMultiline = false,
  });

  @override
  State<TextInputDialog> createState() => _TextInputDialogState();
}

class _TextInputDialogState extends State<TextInputDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonConfirmDialog(
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLines: widget.isMultiline ? null : 1,
        onSubmitted: (value) {
          widget.onSubmitted?.call(value);
          Navigator.of(context).pop();
        },
      ),
      onCancelled: widget.onCancelled,
      onConfirmed: () => widget.onSubmitted?.call(_controller.text),
    );
  }
}

/// Dialog for word input with autocompletion from a provided word index.
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

  @override
  Widget build(BuildContext context) {
    return CommonConfirmDialog(
      content: WordInputField(
        textEditingController: _controller,
        wordIndexMap: wordIndex != null
            ? {'default': (input) => wordIndex!(input)}
            : {},
        showDictionaryName: false,
        onSubmitted: (word, _) {
          onSubmitted?.call(word);
          Navigator.of(context).pop();
        },
        autofocus: true,
      ),
      onConfirmed: () => onSubmitted?.call(_controller.text),
      onCancelled: onCancelled,
    );
  }
}
