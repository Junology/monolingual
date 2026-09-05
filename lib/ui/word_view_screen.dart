import 'package:flutter/material.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/dialogs.dart';
import 'package:monolingual/ui/word_view_widget.dart';

class WordViewScreen extends PageRoute<void> with MaterialRouteTransitionMixin {
  final Dictionary dictionary;
  final String word;

  WordViewScreen({required this.dictionary, required this.word})
    : super(settings: RouteSettings(name: '/word/$word'));

  @override
  Widget buildContent(BuildContext context) =>
      _WordViewBody(dictionary: dictionary, word: word);

  @override
  bool get maintainState => true;

  @override
  String get debugLabel => '${super.debugLabel}(${super.settings.name})';
}

class _WordViewBody extends StatefulWidget {
  final Dictionary dictionary;
  final String word;

  const _WordViewBody({required this.dictionary, required this.word});

  @override
  State<_WordViewBody> createState() => _WordViewBodyState();
}

class _WordViewBodyState extends State<_WordViewBody> {
  late WordRecord _record;
  // The last version persisted to the dictionary; null means the word is new.
  WordRecord? _savedRecord;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecord();
  }

  Future<void> _loadRecord() async {
    final found = await widget.dictionary.find(widget.word);
    setState(() {
      _savedRecord = found;
      _record = found?.clone() ?? WordRecord.newWord(widget.word);
      _isLoading = false;
    });
  }

  Future<void> _save() async {
    if (_savedRecord == null) {
      await widget.dictionary.add(_record);
    } else {
      await widget.dictionary.update(_record);
    }
    setState(() => _savedRecord = _record.clone());
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            onPressed: (_record == _savedRecord) ? null : _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: WordViewWidget(
          wordRecord: _record,
          onVariantAdd: () {
            showDialog(
              context: context,
              builder: (context) => WordInputDialog(
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_record.variants.contains(value)) {
                    setState(() => _record.variants.add(value));
                  }
                },
              ),
            );
          },
          onVariantDelete: (variant) {
            setState(() => _record.variants.remove(variant));
          },
          onSynonymAdd: () {
            showDialog(
              context: context,
              builder: (context) => WordInputDialog(
                wordIndex: widget.dictionary.isearch,
                onSubmitted: (value) {
                  if (value.isNotEmpty && !_record.synonyms.contains(value)) {
                    setState(() => _record.synonyms.add(value));
                  }
                },
              ),
            );
          },
          onSynonymTap: (synonym) {
            Navigator.push(
              context,
              WordViewScreen(dictionary: widget.dictionary, word: synonym),
            );
          },
          onSynonymDelete: (synonym) {
            setState(() => _record.synonyms.remove(synonym));
          },
          onExampleAdd: () {
            showDialog(
              context: context,
              builder: (context) => TextInputDialog(
                onSubmitted: (value) =>
                    setState(() => _record.usageExamples.add(value)),
              ),
            );
          },
          onExampleDelete: (index) {
            setState(() => _record.usageExamples.removeAt(index));
          },
        ),
      ),
    );
  }
}
