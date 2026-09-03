import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide AboutDialog;
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/word_view_screen.dart';
import 'package:monolingual/ui/word_input_widget.dart';
import 'package:monolingual/ui/text_filter_widget.dart';
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
  late final ValueNotifier<Iterable<String>> _filteredDictionariesNotifier;

  @override
  void initState() {
    super.initState();
    _wordInputController = TextEditingController();
    _dictionaryNameNotifier = ValueNotifier<String?>(null);
    _filteredDictionariesNotifier = ValueNotifier<Iterable<String>>(
      widget.dictionaries.keys,
    );
    _filteredDictionariesNotifier.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _wordInputController.dispose();
    _dictionaryNameNotifier.dispose();
    _filteredDictionariesNotifier.dispose();
    super.dispose();
  }

  void _gotoWord(BuildContext context, String word, String? dictionaryName) {
    dictionaryName ??= _filteredDictionariesNotifier.value.singleOrNull;
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
                  // TODO: Direct update the dictionaries map is not ideal, consider using a state management solution
                  showDialog(
                    context: context,
                    builder: (_) => TextInputDialog(
                      onSubmitted: (name) => setState(
                        () => widget.dictionaries[name] = Dictionary.from([]),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.search),
              Expanded(
                child: WordInputField(
                  wordIndexMap: Map.fromEntries(
                    _filteredDictionariesNotifier.value
                        .where(
                          (dictName) =>
                              widget.dictionaries.containsKey(dictName),
                        )
                        .map(
                          (dictName) => MapEntry(
                            dictName,
                            widget.dictionaries[dictName]!.isearch,
                          ),
                        ),
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
