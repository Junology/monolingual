import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

import '../core/dictionary.dart';
import 'synonym_view_widget.dart';

class QuizScreen extends PageRoute<void> with MaterialRouteTransitionMixin {
  final Dictionary dictionary;
  final FutureOr<String> Function()? wordChooser;

  QuizScreen({required this.dictionary, this.wordChooser})
    : super(settings: RouteSettings(name: '/quiz'));

  @override
  Widget buildContent(BuildContext context) =>
      _QuizScreenBody(dictionary: dictionary, wordChooser: wordChooser);

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${super.settings.name})';
}

class _QuizScreenBody extends StatefulWidget {
  final Dictionary dictionary;
  final FutureOr<String> Function()? wordChooser;

  const _QuizScreenBody({required this.dictionary, required this.wordChooser});

  @override
  State<_QuizScreenBody> createState() => _QuizScreenBodyState();
}

class _QuizScreenBodyState extends State<_QuizScreenBody> {
  late Dictionary _dictionary;
  late FutureOr<String> Function() _wordChooser;
  String? _word;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late ValueNotifier<Color> _fieldBorderColorNotifier;
  bool _fieldEnabled = true;

  static const Color defaultFieldBorderColor = Colors.indigo;
  static const Color incorrectFieldBorderColor = Colors.red;
  static const Color correctFieldBorderColor = Colors.green;

  String _defaultWordChooser() {
    final size = _dictionary.size;
    return _dictionary.atIndex(Random().nextInt(size));
  }

  Future<void> _chooseWord() async {
    final String word = await _wordChooser();
    setState(() => _word = word);
  }

  Future<void> _transitionToNextWord() async {
    setState(() => _fieldEnabled = false);
    await Future.delayed(const Duration(milliseconds: 500));
    await _chooseWord();

    // Reset TextField
    _controller.clear();
    setState(() => _fieldEnabled = true);
    _fieldBorderColorNotifier.value = defaultFieldBorderColor;

    // Wait until the TextField is enabled before moving the focus to it.
    await Future.delayed(const Duration(milliseconds: 16));
    _focusNode.requestFocus();
  }

  @override
  void initState() {
    super.initState();
    _dictionary = widget.dictionary;
    _wordChooser = widget.wordChooser ?? _defaultWordChooser;
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _fieldBorderColorNotifier = ValueNotifier<Color>(defaultFieldBorderColor);
    _chooseWord();
  }

  @override
  void didUpdateWidget(covariant _QuizScreenBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool needRefresh = false;

    if (widget.dictionary != oldWidget.dictionary) {
      _dictionary = widget.dictionary;
      needRefresh = true;
    }
    if (widget.wordChooser != oldWidget.wordChooser) {
      _wordChooser = widget.wordChooser ?? _defaultWordChooser;
      needRefresh = true;
    }
    if (needRefresh) {
      _chooseWord();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _fieldBorderColorNotifier.dispose();
    super.dispose();
  }

  void _validateField() {
    debugPrint('Validating field: input="${_controller.text}", word="$_word"');
    if (_controller.text == _word) {
      _fieldBorderColorNotifier.value = correctFieldBorderColor;
      _transitionToNextWord();
    } else {
      _fieldBorderColorNotifier.value = incorrectFieldBorderColor;
    }
  }

  AppBar _buildAppBar() {
    const color = Colors.orange;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.navigate_before),
        onPressed: () => Navigator.of(context).pop(),
      ),
      backgroundColor: color,
      elevation: 4.0,
      shadowColor: color.shade800,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _word == null
          ? const CircularProgressIndicator()
          : Column(
              children: [
                Expanded(
                  child: SynonymView(
                    dictionary: _dictionary,
                    word: _word!,
                    searchDepth: 2,
                    visibleDepth: 1,
                    labelBuilder: (word) {
                      return Container(
                        color: word == _word
                            ? Colors.black
                            : Colors.transparent,
                        child: Text(
                          word == _word ? 'XXXXX' : word,
                          style: TextStyle(
                            color: word == _word
                                ? Colors.transparent
                                : Colors.black,
                          ),
                        ),
                      );
                    },
                    scale: 50.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      ValueListenableBuilder(
                        valueListenable: _fieldBorderColorNotifier,
                        builder: (BuildContext context, Color borderColor, _) {
                          return Expanded(
                            child: TextField(
                              focusNode: _focusNode,
                              controller: _controller,
                              autofocus: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: borderColor),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: borderColor,
                                    width: 2.0,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: borderColor),
                                ),
                              ),
                              onChanged: (value) =>
                                  _fieldBorderColorNotifier.value =
                                      defaultFieldBorderColor,
                              onSubmitted: (_) => _validateField(),
                              enabled: _fieldEnabled,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.subdirectory_arrow_left),
                        onPressed: _validateField,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
