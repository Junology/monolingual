import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:monolingual/core/word_record.dart';

class WordViewWidget extends StatelessWidget {
  final WordRecord wordRecord;
  final void Function()? onVariantAdd;
  final void Function(String)? onVariantDelete;
  final void Function()? onSynonymAdd;
  final void Function(String)? onSynonymTap;
  final void Function(String)? onSynonymDelete;
  final void Function()? onExampleAdd;
  final void Function(int)? onExampleDelete;

  const WordViewWidget({
    super.key,
    required this.wordRecord,
    this.onVariantAdd,
    this.onVariantDelete,
    this.onSynonymAdd,
    this.onSynonymTap,
    this.onSynonymDelete,
    this.onExampleAdd,
    this.onExampleDelete,
  });

  Widget _buildHeadline(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: Text(
        wordRecord.word,
        style: Theme.of(context).textTheme.headlineLarge,
      ),
    );
  }

  Widget _buildVariants(BuildContext context) {
    final entryStyle = Theme.of(context).textTheme.bodyMedium;

    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(Icons.fork_right, color: Colors.grey, size: 32.0),
          ),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ...wordRecord.variants.map((variant) {
                  return Chip(
                    label: Text(variant, style: entryStyle),
                    onDeleted: onVariantDelete != null
                        ? () => onVariantDelete!.call(variant)
                        : null,
                  );
                }),
                if (onVariantAdd != null)
                  ActionChip(
                    label: Icon(
                      Icons.add,
                      size: (entryStyle?.fontSize ?? 14.0) * 1.414,
                    ),
                    onPressed: () => onVariantAdd?.call(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSynonyms(BuildContext context) {
    final entryStyle = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(192, 200, 230, 255),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Icon(
              Icons.compare_arrows,
              color: Colors.blueGrey,
              size: 32.0,
            ),
          ),
          Expanded(
            child: Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: [
                ...wordRecord.synonyms.map((synonym) {
                  return GestureDetector(
                    onTap: () => onSynonymTap?.call(synonym),
                    child: Chip(
                      label: Text(synonym, style: entryStyle),
                      onDeleted: () => onSynonymDelete?.call(synonym),
                    ),
                  );
                }),
                if (onSynonymAdd != null)
                  ActionChip(
                    label: Icon(
                      Icons.add,
                      size: (entryStyle?.fontSize ?? 14.0) * 1.414,
                    ),
                    onPressed: () => onSynonymAdd?.call(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageExamples(BuildContext context) {
    final entryStyle = Theme.of(context).textTheme.bodyMedium;
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Color.fromARGB(192, 255, 230, 200),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: const Icon(
              Icons.rate_review,
              color: Colors.deepOrange,
              size: 32.0,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 2.0,
            children: [
              ...wordRecord.usageExamples.mapIndexed(
                (index, example) => Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width - 64,
                  ),
                  child: Material(
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.arrow_right),
                      title: Text(example, style: entryStyle, softWrap: true),
                      trailing: onExampleDelete != null
                          ? IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => onExampleDelete!.call(index),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              if (onExampleAdd != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: ActionChip(
                    label: Icon(
                      Icons.add,
                      size: (entryStyle?.fontSize ?? 14.0) * 1.414,
                    ),
                    onPressed: () => onExampleAdd?.call(),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeadline(context),
        _buildVariants(context),
        _buildSynonyms(context),
        _buildUsageExamples(context),
      ],
    );
  }
}
