import 'dart:collection';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/word_view_screen.dart';
import 'package:monolingual/ui/word_input_widget.dart';
import 'package:monolingual/ui/text_filter_widget.dart';
import 'package:monolingual/ui/synonym_view_widget.dart';
import 'package:monolingual/ui/dialogs.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, Dictionary> dictionaries;

  const HomeScreen({super.key, required this.dictionaries});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _wordInputController;
  late final ValueNotifier<String?> _dictionaryNameNotifier;

  // [ValueNotifier] for the list of the names of dictionaries that match the
  // current filter in [_dictionaryNameNotifier] and contains the word specified
  // as the value of [_wordInputController].
  late final ValueNotifier<Iterable<String>> _filteredDictionariesNotifier;

  late final ValueNotifier<({Dictionary dictionary, String word})?>
  _wordNotifier;
  @override
  void initState() {
    super.initState();

    _wordInputController = TextEditingController();
    _dictionaryNameNotifier = ValueNotifier<String?>(null);
    _filteredDictionariesNotifier = ValueNotifier<Iterable<String>>(
      widget.dictionaries.keys,
    );
    _wordNotifier = ValueNotifier<({Dictionary dictionary, String word})?>(
      null,
    );
  }

  @override
  void dispose() {
    _wordInputController.dispose();
    _dictionaryNameNotifier.dispose();
    _filteredDictionariesNotifier.dispose();
    _wordNotifier.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dictionaries != oldWidget.dictionaries) {
      _filteredDictionariesNotifier.value = widget.dictionaries.keys;
    }
  }

  Future<void> _addDictionary(String name) async {
    // Do nothing when the dictionary already exists.
    if (widget.dictionaries.keys.contains(name)) return;

    final dict = await DBDictionary.openFromDB(name);
    setState(() => widget.dictionaries[name] = dict);
  }

  void _updateDisplayedWord(String word, String? dictionaryName) {
    dictionaryName ??= _filteredDictionariesNotifier.value.singleOrNull;

    debugPrint(
      'Updating displayed word: $word, dictionaryName: $dictionaryName',
    );
    if (dictionaryName == null || word.isEmpty) return;
    final dictionary = widget.dictionaries[dictionaryName];
    if (dictionary == null) return;

    _wordNotifier.value = (dictionary: dictionary, word: word);
  }

  void _gotoWord(BuildContext context, String word, Dictionary dictionary) {
    debugPrint('Word tapped: $word');
    Navigator.push(context, WordViewScreen(dictionary: dictionary, word: word));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        foregroundColor: Theme.of(context).colorScheme.onInverseSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.info, color: Colors.white),
            onPressed: () {
              // `AboutDialog` is from `dialogs.dart`; not the one from Flutter.
              showDialog(context: context, builder: (_) => const AboutDialog());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.book),
              Expanded(
                child: TextFilterWidget(
                  items: widget.dictionaries.keys.toList(),
                  searchMode: SearchMode.regex,
                  filteredItemsNotifier: _filteredDictionariesNotifier,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        TextInputDialog(onSubmitted: _addDictionary),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.search),
              Expanded(
                child: ValueListenableBuilder<Iterable<String>>(
                  valueListenable: _filteredDictionariesNotifier,
                  builder: (context, filteredDictionaries, child) {
                    return WordInputField(
                      wordIndexMap: Map.fromEntries(
                        filteredDictionaries.map(
                          (dictName) => MapEntry(
                            dictName,
                            widget.dictionaries[dictName]!.isearch,
                          ),
                        ),
                      ),
                      showDictionaryName: true,
                      onSubmitted: _updateDisplayedWord,
                      textEditingController: _wordInputController,
                      dictionaryNameNotifier: _dictionaryNameNotifier,
                    );
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  _updateDisplayedWord(
                    _wordInputController.text,
                    _dictionaryNameNotifier.value,
                  );
                },
                icon: const Icon(Icons.subdirectory_arrow_left),
              ),
            ],
          ),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _wordNotifier,
              builder: (context, value, child) {
                if (value == null) {
                  return const SizedBox.shrink();
                }
                return SynonymView(
                  dictionary: value.dictionary,
                  word: value.word,
                  searchDepth: 3,
                  visibleDepth: 2,
                  onWordTapped: (word) =>
                      _gotoWord(context, word, value.dictionary),
                  scale: 50,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
