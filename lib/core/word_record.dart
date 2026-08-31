import 'dart:collection';
import 'package:collection/collection.dart';

/// Record type for a word.
/// Each word record contains the word itself, a list of variant forms, a list
/// of synonyms, and a list of usage examples.
class WordRecord {
  /// The word itself in primary form.
  final String word;

  /// A list of variant forms of the word, such as plural forms or different tenses.
  /// The list is sorted in ascending order.
  List<String> variants;

  /// A list of synonyms for the word.
  LinkedHashSet<String> synonyms;

  /// A list of usage examples for the word.
  List<String> usageExamples;

  /// The number of synonyms for the word.
  int get synonymsCount => synonyms.length;

  /// Creates a new instance of [WordRecord].
  /// This is meant to be used to construct a [WordRecord] from existing data.
  /// For adding a new word, use [WordRecord.newWord] instead.
  ///
  /// [word] is the word itself.
  /// [variants] is a sorted list of variant forms of the word.
  /// [synonyms] is a list of synonyms for the word.
  /// [usageExamples] is a list of usage examples for the word.
  WordRecord(
    this.word, {
    required this.variants,
    required this.synonyms,
    required this.usageExamples,
  });

  /// Creates a new [WordRecord] for a new word.
  /// This constructor initializes [variants], [synonyms], and [usageExamples]
  /// to empty.
  factory WordRecord.newWord(
    String word, {
    List<String>? variants,
    List<String>? synonyms,
    List<String>? usageExamples,
  }) {
    variants ??= [];
    variants.sort();
    return WordRecord(
      word,
      variants: variants,
      synonyms: LinkedHashSet<String>.from(synonyms ?? []),
      usageExamples: usageExamples ?? [],
    );
  }

  /// Deep copy for [WordRecord].
  WordRecord clone() {
    return WordRecord(
      word.substring(0), // Create a new string instance
      variants: List<String>.from(variants),
      synonyms: LinkedHashSet<String>.from(synonyms),
      usageExamples: List<String>.from(usageExamples),
    );
  }

  /// Adds a new variant form to the word.
  /// Returns true if the variant was added, false if it was already present.
  ///
  bool addVariant(String variant) {
    // == WARNING ==
    // The method uses binary search to find the correct position for the new
    // variant in [variants].
    // Make sure that [variants] is sorted before calling this method.
    // ==
    int low = 0, high = variants.length - 1;
    while (low <= high) {
      int mid = (low + high) ~/ 2;
      if (variants[mid] == variant) {
        return false; // Variant already exists
      } else if (variants[mid].compareTo(variant) < 0) {
        low = mid + 1;
      } else {
        high = mid - 1;
      }
    }
    variants.insert(low, variant);
    return true;
  }

  // Remove a variant form from the word.
  /// Returns true if the variant was removed, false if it was not present.
  bool removeVariant(String variant) => variants.remove(variant);

  /// Replace the list of variants with a new list.
  void replaceVariants(List<String> newVariants) {
    variants = List<String>.from(newVariants);
    variants.sort();
  }

  /// Adds a new synonym to the word.
  /// Returns true if the synonym was added, false if it was already present.
  bool addSynonym(String synonym) => synonyms.add(synonym);

  /// Removes a synonym from the word.
  /// Returns true if the synonym was removed, false if it was not present.
  bool removeSynonym(String synonym) => synonyms.remove(synonym);

  /// Replaces the list of synonyms with a new list.
  void replaceSynonyms(Iterable<String> newSynonyms) {
    synonyms = LinkedHashSet<String>.from(newSynonyms);
  }

  /// Adds a new usage example for the word.
  /// @remarks This method does not check for duplicates.
  void addUsageExample(String example) => usageExamples.add(example);

  /// Removes a usage example at the specified index.
  /// Returns true if the example was removed, false if the index was out of bounds.
  bool removeUsageExampleAt(int index) {
    if (index < 0 || index >= usageExamples.length) return false;
    usageExamples.removeAt(index);
    return true;
  }

  /// Replaces the list of usage examples with a new list.
  void replaceUsageExamples(List<String> newExamples) {
    usageExamples = List<String>.from(newExamples);
  }

  /// Equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is WordRecord &&
        other.word == word &&
        other.variants.equals(variants) &&
        const SetEquality().equals(other.synonyms, synonyms) &&
        other.usageExamples.equals(usageExamples);
  }

  /// Hash code
  @override
  int get hashCode => Object.hash(
    word,
    const ListEquality<String>().hash(variants),
    const SetEquality<String>().hash(synonyms),
    const ListEquality<String>().hash(usageExamples),
  );

  /// String representation of the word record.
  @override
  String toString() {
    return 'WordRecord(word: $word, variants: $variants, synonyms: $synonyms, usageExamples: $usageExamples)';
  }
}
