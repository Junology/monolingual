import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:monolingual/ui/home_screen.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/service/database.dart';
import 'package:monolingual/appinfo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.initialize();
  await DBService.initialize(
    dbPath: p.join(AppInfo.dbDir, '${AppInfo.name}.db'),
  );

  runApp(MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    Dictionary nounDictionary = InMemoryDictionary.from([
      WordRecord.newWord(
        'test',
        variants: ['tests'],
        synonyms: ['experiment', 'exam', 'quiz', 'trial', 'examination'],
        usageExamples: [
          'This test can be failed.',
          'Another example of a test.',
          'Yet another test example.',
        ],
      ),
      WordRecord.newWord(
        'exam',
        variants: ['exams'],
        synonyms: ['test', 'quiz', 'trial', 'examination'],
      ),
      WordRecord.newWord(
        'quiz',
        variants: ['quizzes'],
        synonyms: ['test', 'exam', 'trial', 'examination'],
      ),
      WordRecord.newWord(
        'trial',
        variants: ['trials'],
        synonyms: ['test', 'exam', 'quiz', 'examination'],
      ),
      WordRecord.newWord(
        'examination',
        variants: ['examinations'],
        synonyms: ['test', 'exam', 'quiz', 'trial'],
      ),
    ]);
    Dictionary verbDictionary = InMemoryDictionary.from([
      WordRecord.newWord(
        'test',
        variants: ['tests', 'testing', 'tested'],
        synonyms: ['experiment', 'examine', 'check', 'verify'],
        usageExamples: ['The hypothesis has not been tested yet.'],
      ),
      WordRecord.newWord(
        'experiment',
        variants: ['experiments', 'experimenting', 'experimented'],
        synonyms: ['test', 'examine', 'check', 'verify'],
      ),
      WordRecord.newWord(
        'examine',
        variants: ['examines', 'examined', 'examining'],
        synonyms: ['test', 'experiment', 'check', 'verify'],
      ),
    ]);

    return MaterialApp(
      home: HomeScreen(
        dictionaries: {'noun': nounDictionary, 'verb': verbDictionary},
      ),
    );
  }
}
