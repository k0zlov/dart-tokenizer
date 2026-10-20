import 'dart:convert';

import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';
import 'package:dart_tokenizer/src/base/trainer.dart';
import 'package:dart_tokenizer/src/bpe/base/bpe_training_info.dart';
import 'package:dart_tokenizer/src/bpe/base/byte_vocabulary.dart';
import 'package:dart_tokenizer/src/bpe/base/merge_rule.dart';
import 'package:dart_tokenizer/src/bpe/tokenizers/bpe_tokenizer.dart';

final class BpeTrainer implements TokenizerTrainer<BpeTokenizer> {
  const BpeTrainer({this.minPairFrequency = 2});

  final int minPairFrequency;

  @override
  BpeTokenizer train(
    String corpus, {
    required String name,
    required int vocabularySize,
    TokenizerProgressCallback? onProgress,
  }) {
    if (vocabularySize < 256) {
      throw ArgumentError.value(vocabularySize, 'vocabularySize', 'Vocabulary size cannot be less than 256');
    }

    if (minPairFrequency < 1) {
      throw ArgumentError.value(minPairFrequency, 'minPairFrequency', 'Minimum pair frequency must be at least 1');
    }

    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();

    final corpusBytes = utf8.encode(corpus);
    final corpusCharacters = corpus.runes.length;

    final vocabulary = ByteVocabulary.byteLevel();
    final merges = <MergeRule>[];

    var tokens = corpusBytes.toList();

    final targetMerges = vocabularySize - 256;

    _notifyProgress(
      onProgress: onProgress,
      vocabulary: vocabulary,
      vocabularySize: vocabularySize,
      merges: merges,
      tokens: tokens,
      targetMerges: targetMerges,
      startedAt: startedAt,
    );

    while (vocabulary.length < vocabularySize) {
      final pair = _findMostFrequentPair(tokens);

      if (pair == null || pair.count < minPairFrequency) {
        break;
      }

      final leftToken = vocabulary.tokenOf(pair.leftId);

      final rightToken = vocabulary.tokenOf(pair.rightId);

      if (leftToken == null || rightToken == null) {
        throw StateError('Token not found in vocabulary');
      }

      final resultId = vocabulary.addMerge(leftToken, rightToken);

      final rule = MergeRule(leftId: pair.leftId, rightId: pair.rightId, resultId: resultId, rank: merges.length);

      merges.add(rule);

      tokens = _mergePair(tokens, pair.leftId, pair.rightId, resultId);

      _notifyProgress(
        onProgress: onProgress,
        vocabulary: vocabulary,
        vocabularySize: vocabularySize,
        merges: merges,
        tokens: tokens,
        targetMerges: targetMerges,
        startedAt: startedAt,
      );
    }

    stopwatch.stop();

    final finishedAt = DateTime.now();

    final trainingInfo = BpeTrainingInfo(
      targetVocabularySize: vocabularySize,
      actualVocabularySize: vocabulary.length,
      minPairFrequency: minPairFrequency,
      corpusCharacters: corpusCharacters,
      corpusBytes: corpusBytes.length,
      trainingDuration: stopwatch.elapsed,
      mergesCount: merges.length,
    );

    _notifyProgress(
      onProgress: onProgress,
      vocabulary: vocabulary,
      vocabularySize: vocabularySize,
      merges: merges,
      tokens: tokens,
      targetMerges: targetMerges,
      startedAt: startedAt,
      finishedAt: finishedAt,
      isCompleted: true,
    );

    return BpeTokenizer(name: name, vocabulary: vocabulary, merges: merges, trainingInfo: trainingInfo);
  }

  void _notifyProgress({
    required TokenizerProgressCallback? onProgress,
    required ByteVocabulary vocabulary,
    required int vocabularySize,
    required List<MergeRule> merges,
    required List<int> tokens,
    required int targetMerges,
    required DateTime startedAt,
    DateTime? finishedAt,
    bool isCompleted = false,
  }) {
    final progress = targetMerges == 0 ? 1.0 : merges.length / targetMerges;

    onProgress?.call(
      TokenizerProgress(
        operation: TokenizerOperation.training,
        progress: progress.clamp(0.0, 1.0),
        current: merges.length,
        total: targetMerges,
        unit: 'merges',
        stage: isCompleted ? 'Completed' : 'Learning merge rules',
        isCompleted: isCompleted,
        startedAt: startedAt,
        updatedAt: finishedAt ?? DateTime.now(),
        finishedAt: finishedAt,
        details: {
          'currentVocabularySize': vocabulary.length,
          'targetVocabularySize': vocabularySize,
          'currentTokenCount': tokens.length,
          'minPairFrequency': minPairFrequency,
        },
      ),
    );
  }

  _PairFrequency? _findMostFrequentPair(List<int> tokens) {
    if (tokens.length < 2) {
      return null;
    }

    final frequencies = <(int, int), int>{};

    for (var i = 0; i < tokens.length - 1; i++) {
      final pair = (tokens[i], tokens[i + 1]);

      frequencies[pair] = (frequencies[pair] ?? 0) + 1;
    }

    (int, int)? bestPair;
    var bestCount = 0;

    for (final entry in frequencies.entries) {
      if (entry.value > bestCount) {
        bestPair = entry.key;
        bestCount = entry.value;
      }
    }

    if (bestPair == null) {
      return null;
    }

    return _PairFrequency(leftId: bestPair.$1, rightId: bestPair.$2, count: bestCount);
  }

  List<int> _mergePair(List<int> tokens, int leftId, int rightId, int resultId) {
    final result = <int>[];

    var i = 0;

    while (i < tokens.length) {
      if (i < tokens.length - 1 && tokens[i] == leftId && tokens[i + 1] == rightId) {
        result.add(resultId);
        i += 2;
      } else {
        result.add(tokens[i]);
        i++;
      }
    }

    return result;
  }
}

final class _PairFrequency {
  const _PairFrequency({required this.leftId, required this.rightId, required this.count});

  final int leftId;
  final int rightId;
  final int count;
}
