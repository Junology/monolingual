import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:monolingual/ui/home_screen.dart';
import 'package:monolingual/core/dictionary.dart';
import 'package:monolingual/service/database.dart';
import 'package:monolingual/appinfo.dart';

void main() async {
  // Initialize backend services and app info.
  WidgetsFlutterBinding.ensureInitialized();
  await AppInfo.initialize();
  await DBService.initialize(
    dbPath: p.join(AppInfo.dbDir, '${AppInfo.name}.db'),
  );

  // Load dictionaries from the database
  final dbService = DBService();
  final dictionaryNames = await dbService.dictionaryNames();

  final dictionaries = {
    for (final name in dictionaryNames)
      name: await DBDictionary.openFromDB(name),
  };

  // Launch UI
  runApp(MainApp(dictionaries: dictionaries));
}

class MainApp extends StatelessWidget {
  final Map<String, Dictionary> dictionaries;

  const MainApp({super.key, required this.dictionaries});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: HomeScreen(dictionaries: {...dictionaries}));
  }
}
