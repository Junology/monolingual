import 'package:flutter/material.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/dialogs.dart';
import 'package:monolingual/ui/word_view_widget.dart';

class WordViewScreen extends PageRoute<void> with MaterialRouteTransitionMixin {
  final Dictionary dictionary;
  final String word;
  WordRecord record;

  WordViewScreen({required this.dictionary, required this.word})
    : record = dictionary.find(word)?.clone() ?? WordRecord.newWord(word),
      super(settings: RouteSettings(name: '/word/$word'));

  @override
  Widget buildContent(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) => _buildStateful(context, setState),
    );
  }

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${super.settings.name})';

  Widget _buildStateful(
    BuildContext context,
    void Function(void Function()) setState,
  ) {
    final recordInDict = dictionary.find(word);
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 128.0,
        leading: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.navigate_before),
              onPressed: () => Navigator.of(context).pop(),
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: (recordInDict == record)
                ? null
                : () => setState(() {
                    if (recordInDict == null) {
                      dictionary.add(record);
                    } else {
                      dictionary.update(record);
                    }
                  }),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: WordViewWidget(
          wordRecord: record,
          onVariantAdd: () {
            showDialog(
              context: context,
              builder: (context) => WordInputDialog(
                onSubmitted: (value) {
                  if (value.isNotEmpty && !record.variants.contains(value)) {
                    setState(() => record.variants.add(value));
                  }
                },
              ),
            );
          },
          onVariantDelete: (variant) {
            setState(() => record.variants.remove(variant));
          },
          onSynonymAdd: () {
            showDialog(
              context: context,
              builder: (context) => WordInputDialog(
                wordIndex: (input) => dictionary.isearch(input),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !record.synonyms.contains(value)) {
                    setState(() => record.synonyms.add(value));
                  }
                },
              ),
            );
          },
          onSynonymTap: (synonym) {
            Navigator.push(
              context,
              WordViewScreen(dictionary: dictionary, word: synonym),
            );
          },
          onSynonymDelete: (synonym) {
            setState(() => record.synonyms.remove(synonym));
          },
          onExampleAdd: () {
            showDialog(
              context: context,
              builder: (context) => TextInputDialog(
                onSubmitted: (value) =>
                    setState(() => record.usageExamples.add(value)),
              ),
            );
          },
          onExampleDelete: (index) {
            setState(() => record.usageExamples.removeAt(index));
          },
        ),
      ),
    );
  }
}
