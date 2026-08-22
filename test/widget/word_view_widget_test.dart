import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:monolingual/core/word_record.dart';
import 'package:monolingual/ui/word_view_widget.dart';

// Pump WordViewWidget inside a scrollable MaterialApp scaffold.
Future<void> _pump(
  WidgetTester tester,
  WordRecord record, {
  void Function()? onVariantAdd,
  void Function(String)? onVariantDelete,
  void Function()? onSynonymAdd,
  void Function(String)? onSynonymTap,
  void Function(String)? onSynonymDelete,
  void Function()? onExampleAdd,
  void Function(int)? onExampleDelete,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: WordViewWidget(
          wordRecord: record,
          onVariantAdd: onVariantAdd,
          onVariantDelete: onVariantDelete,
          onSynonymAdd: onSynonymAdd,
          onSynonymTap: onSynonymTap,
          onSynonymDelete: onSynonymDelete,
          onExampleAdd: onExampleAdd,
          onExampleDelete: onExampleDelete,
        ),
      ),
    ),
  ),
);

void main() {
  group('WordViewWidget – display', () {
    late WordRecord record;

    setUp(() {
      record = WordRecord.newWord(
        'flutter',
        variants: ['fluttered', 'flutters'],
        synonyms: ['vibrate', 'waver', 'flicker'],
        usageExamples: [
          'The flag flutters in the wind.',
          'Her heart fluttered.',
        ],
      );
    });

    testWidgets('headline word is rendered as a Text widget', (tester) async {
      await _pump(tester, record);
      expect(find.text('flutter'), findsOneWidget);
    });

    testWidgets('all variants are rendered as Chip widgets', (tester) async {
      await _pump(tester, record);
      for (final v in record.variants) {
        expect(find.widgetWithText(Chip, v), findsOneWidget);
      }
    });

    testWidgets('all synonyms are rendered as Chip widgets', (tester) async {
      await _pump(tester, record);
      for (final s in record.synonyms) {
        expect(find.widgetWithText(Chip, s), findsOneWidget);
      }
    });

    testWidgets('all usage examples are rendered', (tester) async {
      await _pump(tester, record);
      for (final e in record.usageExamples) {
        expect(find.text(e), findsOneWidget);
      }
    });
  });

  group('WordViewWidget – callbacks', () {
    testWidgets('onVariantAdd fires when add-variant ActionChip is tapped', (
      tester,
    ) async {
      bool called = false;
      // Only onVariantAdd is set, so exactly one ActionChip is rendered.
      await _pump(
        tester,
        WordRecord.newWord('flutter'),
        onVariantAdd: () => called = true,
      );
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onVariantDelete fires with the correct variant', (
      tester,
    ) async {
      String? deleted;
      await _pump(
        tester,
        WordRecord.newWord('flutter', variants: ['flutters']),
        onVariantDelete: (v) => deleted = v,
      );
      tester.widget<Chip>(find.widgetWithText(Chip, 'flutters')).onDeleted!();
      expect(deleted, 'flutters');
    });

    testWidgets('onSynonymAdd fires when add-synonym ActionChip is tapped', (
      tester,
    ) async {
      bool called = false;
      // Only onSynonymAdd is set, so exactly one ActionChip is rendered.
      await _pump(
        tester,
        WordRecord.newWord('flutter'),
        onSynonymAdd: () => called = true,
      );
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onSynonymTap fires with the correct synonym', (tester) async {
      String? tapped;
      await _pump(
        tester,
        WordRecord.newWord('flutter', synonyms: ['vibrate']),
        onSynonymTap: (s) => tapped = s,
      );
      await tester.tap(find.widgetWithText(Chip, 'vibrate'));
      await tester.pump();
      expect(tapped, 'vibrate');
    });

    testWidgets('onSynonymDelete fires with the correct synonym', (
      tester,
    ) async {
      String? deleted;
      await _pump(
        tester,
        WordRecord.newWord('flutter', synonyms: ['vibrate']),
        onSynonymDelete: (s) => deleted = s,
      );
      tester.widget<Chip>(find.widgetWithText(Chip, 'vibrate')).onDeleted!();
      expect(deleted, 'vibrate');
    });

    testWidgets('onExampleAdd fires when add-example ActionChip is tapped', (
      tester,
    ) async {
      bool called = false;
      // Only onExampleAdd is set, so exactly one ActionChip is rendered.
      await _pump(
        tester,
        WordRecord.newWord('flutter'),
        onExampleAdd: () => called = true,
      );
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('onExampleDelete fires with the correct index', (tester) async {
      int? deletedIndex;
      await _pump(
        tester,
        WordRecord.newWord(
          'flutter',
          usageExamples: ['Example one.', 'Example two.'],
        ),
        onExampleDelete: (i) => deletedIndex = i,
      );
      await tester.tap(find.widgetWithIcon(IconButton, Icons.delete).first);
      await tester.pump();
      expect(deletedIndex, 0);
    });
  });

  group('WordViewWidget – add and delete interactions', () {
    testWidgets('adding a variant updates the displayed chips', (tester) async {
      final record = WordRecord.newWord('flutter', variants: ['flutters']);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: WordViewWidget(
                  wordRecord: record,
                  onVariantAdd: () =>
                      setState(() => record.addVariant('fluttered')),
                  onVariantDelete: (v) =>
                      setState(() => record.removeVariant(v)),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(Chip, 'fluttered'), findsNothing);
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(find.widgetWithText(Chip, 'fluttered'), findsOneWidget);
    });

    testWidgets('deleting a variant removes its chip', (tester) async {
      final record = WordRecord.newWord(
        'flutter',
        variants: ['fluttered', 'flutters'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: WordViewWidget(
                  wordRecord: record,
                  onVariantDelete: (v) =>
                      setState(() => record.removeVariant(v)),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(Chip, 'flutters'), findsOneWidget);
      tester.widget<Chip>(find.widgetWithText(Chip, 'flutters')).onDeleted!();
      await tester.pump();
      expect(find.widgetWithText(Chip, 'flutters'), findsNothing);
    });

    testWidgets('adding a synonym updates the displayed chips', (tester) async {
      final record = WordRecord.newWord('flutter', synonyms: ['vibrate']);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: WordViewWidget(
                  wordRecord: record,
                  onSynonymAdd: () =>
                      setState(() => record.addSynonym('waver')),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(Chip, 'waver'), findsNothing);
      await tester.tap(find.byType(ActionChip));
      await tester.pump();
      expect(find.widgetWithText(Chip, 'waver'), findsOneWidget);
    });

    testWidgets('deleting a synonym removes its chip', (tester) async {
      final record = WordRecord.newWord(
        'flutter',
        synonyms: ['vibrate', 'waver'],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => SingleChildScrollView(
                child: WordViewWidget(
                  wordRecord: record,
                  onSynonymDelete: (s) =>
                      setState(() => record.removeSynonym(s)),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.widgetWithText(Chip, 'vibrate'), findsOneWidget);
      tester.widget<Chip>(find.widgetWithText(Chip, 'vibrate')).onDeleted!();
      await tester.pump();
      expect(find.widgetWithText(Chip, 'vibrate'), findsNothing);
    });
  });

  group('WordViewWidget – synonym wrapping', () {
    testWidgets('synonym Chips wrap to multiple rows in a narrow viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(200, 800);
      addTearDown(tester.view.resetPhysicalSize);

      await _pump(
        tester,
        WordRecord.newWord(
          'flutter',
          synonyms: ['synonym-alpha', 'synonym-beta', 'synonym-gamma'],
        ),
      );

      final rows = [
        'synonym-alpha',
        'synonym-beta',
        'synonym-gamma',
      ].map((s) => tester.getTopLeft(find.widgetWithText(Chip, s)).dy).toSet();

      // At least two chips must be on different rows for wrapping to have occurred.
      expect(rows.length, greaterThan(1));
    });
  });
}
