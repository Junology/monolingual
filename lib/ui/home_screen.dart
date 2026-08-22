import 'package:flutter/material.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/ui/word_view_screen.dart';

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

    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              WordViewScreen(dictionary: dictionary, word: 'test'),
            );
          },
          child: const Text('Open Word View'),
        ),
      ),
    );
  }
}
