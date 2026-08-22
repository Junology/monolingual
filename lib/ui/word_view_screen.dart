import 'package:flutter/material.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
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
        leading: IconButton(
          icon: const Icon(Icons.navigate_before),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
          ),
          const Spacer(),
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
          onVariantAdd: () {},
          onVariantDelete: (variant) {},
          onSynonymAdd: () {},
          onSynonymTap: (synonym) {
            Navigator.push(
              context,
              WordViewScreen(dictionary: dictionary, word: synonym),
            );
          },
          onSynonymDelete: (synonym) {},
          onExampleAdd: () {},
          onExampleDelete: (index) {},
        ),
      ),
    );
  }
}
