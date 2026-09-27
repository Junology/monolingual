import 'dart:collection';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:google_fonts/google_fonts.dart';

import '../core/dictionary.dart';

import 'word_view_screen.dart';
import 'word_input_widget.dart';
import 'text_filter_widget.dart';
import 'synonym_view_widget.dart';
import 'quiz_screen.dart';
import 'dialogs.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, Dictionary> dictionaries;

  const HomeScreen({super.key, required this.dictionaries});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const appBarBGColor = Colors.teal;
  static const appBarFGColor = Color.fromARGB(0xFF, 0xEC, 0xEF, 0xF4);

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

    if (dictionaryName == null || word.isEmpty) return;
    final dictionary = widget.dictionaries[dictionaryName];
    if (dictionary == null) return;

    _wordNotifier.value = (dictionary: dictionary, word: word);
  }

  void _gotoWord(BuildContext context, String word, Dictionary dictionary) {
    Navigator.push(context, WordViewScreen(dictionary: dictionary, word: word));
  }

  Future<Dictionary?> showDictionaryChooser(BuildContext context) async {
    String? dictionaryName = await showDialog<String>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          children: [
            ..._filteredDictionariesNotifier.value.map((name) {
              return SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, name);
                },
                child: Text(name),
              );
            }),
            IconButton(
              icon: const Icon(Icons.cancel),
              color: Colors.red,
              onPressed: () {
                Navigator.pop(context, null);
              },
            ),
          ],
        );
      },
    );
    return dictionaryName != null ? widget.dictionaries[dictionaryName] : null;
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: appBarBGColor,
      foregroundColor: appBarFGColor,
      elevation: 4.0,
      shadowColor: appBarBGColor.shade800,
      // Title logo
      // For fonts: see https://www.vulgarlang.com/ipafonts/
      title: Text(
        'Mɒn.əʊˈlɪŋ.ɡwəl',
        style: GoogleFonts.lato(
          fontSize: Theme.of(context).textTheme.titleLarge?.fontSize ?? 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info, color: Colors.white),
          onPressed: () {
            // `AboutDialog` is from `dialogs.dart`; not the one from Flutter.
            showDialog(context: context, builder: (_) => const AboutDialog());
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.passthrough,
              children: [
                ValueListenableBuilder(
                  valueListenable: _wordNotifier,
                  builder: (context, value, child) {
                    if (value == null) {
                      return const SizedBox.expand();
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
                Positioned(
                  bottom: 16.0,
                  right: 16.0,
                  child: FloatingActionButton(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    hoverColor: Colors.grey.shade700,
                    elevation: 6.0,
                    onPressed: () {
                      showDictionaryChooser(context).then((dictionary) {
                        if (dictionary != null && context.mounted) {
                          Navigator.push(
                            context,
                            QuizScreen(dictionary: dictionary),
                          );
                        }
                      });
                    },
                    shape: const CircleBorder(),
                    child: const Icon(Icons.quiz),
                  ),
                ),
              ],
            ),
          ),
          /*
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
          */
          Container(
            padding: const EdgeInsets.all(8.0),
            color: appBarBGColor.shade100,
            child: Column(
              children: [
                Row(
                  spacing: 3.0,
                  children: [
                    const Icon(Icons.book),
                    Expanded(
                      child: TextFilterWidget(
                        items: widget.dictionaries.keys.toList(),
                        searchMode: SearchMode.regex,
                        filteredItemsNotifier: _filteredDictionariesNotifier,
                        optionsViewOpenDirection: OptionsViewOpenDirection.up,
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade100.withAlpha(208),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) =>
                                TextInputDialog(onSubmitted: _addDictionary),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Row(
                  spacing: 3.0,
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
                            optionsViewOpenDirection:
                                OptionsViewOpenDirection.up,
                          );
                        },
                      ),
                    ),
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade100.withAlpha(208),
                      child: IconButton(
                        onPressed: () {
                          _updateDisplayedWord(
                            _wordInputController.text,
                            _dictionaryNameNotifier.value,
                          );
                        },
                        icon: const Icon(Icons.subdirectory_arrow_left),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
