import 'package:flutter/material.dart';
import 'package:monolingual/core/radix_tree.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/word_view_screen.dart';
import 'package:monolingual/ui/word_input_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    WordRecord testRecord = WordRecord.newWord(
      'test',
      variants: ['tests'],
      synonyms: ['experiment', 'exam', 'quiz', 'trial', 'examination'],
      usageExamples: [
        'This test can be failed.',
        'Another example of a test.',
        'Yet another test example.',
      ],
    );
    Dictionary dictionary = Dictionary.from([testRecord]);
    RadixTree verbTree = RadixTree.fromIterable([
      "test",
      "expreriment",
      "exmaine",
    ]);
    RadixTree nounTree = RadixTree.fromIterable([
      "test",
      "exam",
      "quiz",
      "trial",
      "examination",
    ]);

    return Scaffold(
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                WordViewScreen(dictionary: dictionary, word: 'test'),
              );
            },
            child: const Text('Open Word View'),
          ),
          WordInputField(
            wordIndexMap: {
              'verb': (input) => verbTree.wordsWithPrefix(input),
              'noun': (input) => nounTree.wordsWithPrefix(input),
            },
            showDictionaryName: true,
            onSubmitted: (value, dictionaryName) =>
                print('Submitted: $value, Dictionary: $dictionaryName'),
          ),
        ],
      ),
    );
  }
}
