import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/word_view_screen.dart';
import 'package:monolingual/ui/word_input_widget.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, Dictionary> dictionaries;

  const HomeScreen({super.key, required this.dictionaries});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _dictionaryFieldController;
  late final TextEditingController _wordInputController;
  late final ValueNotifier<String?> _dictionaryNameNotifier;

  @override
  void initState() {
    super.initState();
    _dictionaryFieldController = TextEditingController();
    _wordInputController = TextEditingController();
    _dictionaryNameNotifier = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _dictionaryFieldController.dispose();
    _wordInputController.dispose();
    _dictionaryNameNotifier.dispose();
    super.dispose();
  }

  void _gotoWord(BuildContext context, String word, String? dictionaryName) {
    if (dictionaryName == null) return;

    final dictionary = widget.dictionaries[dictionaryName];

    if (dictionary == null) {
      if (kDebugMode) {
        debugPrint('Unknown dictionary name: $dictionaryName');
      }
      return;
    }

    Navigator.push(context, WordViewScreen(dictionary: dictionary, word: word));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.search),
              Expanded(
                child: WordInputField(
                  wordIndexMap: widget.dictionaries.map(
                    (key, value) => MapEntry(key, value.isearch),
                  ),
                  showDictionaryName: true,
                  onSubmitted: (value, dictionaryName) =>
                      _gotoWord(context, value, dictionaryName),
                  textEditingController: _wordInputController,
                  dictionaryNameNotifier: _dictionaryNameNotifier,
                ),
              ),
              IconButton(
                onPressed: () {
                  _gotoWord(
                    context,
                    _wordInputController.text,
                    _dictionaryNameNotifier.value,
                  );
                },
                icon: const Icon(Icons.subdirectory_arrow_left),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
