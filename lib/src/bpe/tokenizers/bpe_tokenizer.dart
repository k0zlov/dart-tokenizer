import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';
import 'package:dart_tokenizer/src/bpe/base/bpe_training_info.dart';
import 'package:dart_tokenizer/src/bpe/base/byte_vocabulary.dart';
import 'package:dart_tokenizer/src/bpe/base/merge_rule.dart';

final class BpeTokenizer implements Tokenizer {
  BpeTokenizer({required this.vocabulary, required List<MergeRule> merges, this.name = 'Custom BPE', this.trainingInfo})
    : _mergeRules = {for (final rule in merges) (rule.leftId, rule.rightId): rule};

  static Future<BpeTokenizer> fromFile(String path) async {
    final content = await File(path).readAsString();
    final json = jsonDecode(content) as Map<String, dynamic>;

    return BpeTokenizer.fromJson(json);
  }

  static BpeTokenizer fromFileSync(String path) {
    final content = File(path).readAsStringSync();
    final json = jsonDecode(content) as Map<String, dynamic>;

    return BpeTokenizer.fromJson(json);
  }

  factory BpeTokenizer.fromJson(Map<String, dynamic> json) {
    final vocabularyJson = json['vocabulary'] as List<dynamic>;

    final vocabulary = ByteVocabulary.fromIdToToken({
      for (final item in vocabularyJson)
        (item as Map<String, dynamic>)['id'] as int: ByteToken((item['bytes'] as List<dynamic>).cast<int>()),
    });

    final mergesJson = json['merges'] as List<dynamic>;

    final merges = mergesJson.map((item) => MergeRule.fromJson((item as Map).cast<String, dynamic>())).toList();

    final trainingJson = json['training'];

    final trainingInfo = trainingJson == null
        ? null
        : BpeTrainingInfo.fromJson((trainingJson as Map).cast<String, dynamic>());

    return BpeTokenizer(
      name: json['name'] as String,
      vocabulary: vocabulary,
      merges: merges,
      trainingInfo: trainingInfo,
    );
  }

  final ByteVocabulary vocabulary;

  final Map<(int, int), MergeRule> _mergeRules;

  final BpeTrainingInfo? trainingInfo;

  List<MergeRule> get merges {
    final merges = _mergeRules.values.toList()..sort((a, b) => a.rank.compareTo(b.rank));

    return List.unmodifiable(merges);
  }

  @override
  final String name;

  @override
  int get vocabularySize => vocabulary.length;

  @override
  List<int> encode(String text, {TokenizerProgressCallback? onProgress}) {
    final startedAt = DateTime.now();

    final tokens = utf8.encode(text).toList(growable: false);

    if (tokens.isEmpty) {
      final finishedAt = DateTime.now();

      _notifyProgress(
        onProgress: onProgress,
        operation: TokenizerOperation.encoding,
        progress: 1,
        current: 0,
        total: _mergeRules.length,
        unit: 'merge rules',
        stage: 'Completed',
        startedAt: startedAt,
        finishedAt: finishedAt,
        isCompleted: true,
        details: {'currentTokenCount': 0, 'mergeOperations': 0},
      );

      return [];
    }

    if (tokens.length == 1 || _mergeRules.isEmpty) {
      final finishedAt = DateTime.now();

      _notifyProgress(
        onProgress: onProgress,
        operation: TokenizerOperation.encoding,
        progress: 1,
        current: _mergeRules.length,
        total: _mergeRules.length,
        unit: 'merge rules',
        stage: 'Completed',
        startedAt: startedAt,
        finishedAt: finishedAt,
        isCompleted: true,
        details: {'currentTokenCount': tokens.length, 'mergeOperations': 0},
      );

      return tokens;
    }

    final length = tokens.length;

    final previous = List<int>.generate(length, (index) => index - 1, growable: false);

    final next = List<int>.generate(length, (index) => index + 1 < length ? index + 1 : -1, growable: false);

    final alive = Uint8List(length)..fillRange(0, length, 1);

    final queue = HeapPriorityQueue<_MergeCandidate>(_compareMergeCandidates);

    void addCandidate(int leftIndex) {
      if (leftIndex < 0 || alive[leftIndex] == 0) {
        return;
      }

      final rightIndex = next[leftIndex];

      if (rightIndex < 0 || alive[rightIndex] == 0) {
        return;
      }

      final rule = _mergeRules[(tokens[leftIndex], tokens[rightIndex])];

      if (rule == null) {
        return;
      }

      queue.add(_MergeCandidate(leftIndex: leftIndex, rightIndex: rightIndex, rank: rule.rank));
    }

    for (var i = 0; i < length - 1; i++) {
      addCandidate(i);
    }

    final totalRules = _mergeRules.length;

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.encoding,
      progress: 0,
      current: 0,
      total: totalRules,
      unit: 'merge rules',
      stage: 'Applying merge rules',
      startedAt: startedAt,
      details: {'currentTokenCount': length, 'mergeOperations': 0},
    );

    var mergeOperations = 0;
    var currentTokenCount = length;
    var lastReportedRank = -1;

    while (queue.isNotEmpty) {
      final candidate = queue.removeFirst();

      final leftIndex = candidate.leftIndex;
      final rightIndex = candidate.rightIndex;

      if (alive[leftIndex] == 0 || alive[rightIndex] == 0 || next[leftIndex] != rightIndex) {
        continue;
      }

      final rule = _mergeRules[(tokens[leftIndex], tokens[rightIndex])];

      if (rule == null || rule.rank != candidate.rank) {
        continue;
      }

      tokens[leftIndex] = rule.resultId;

      alive[rightIndex] = 0;

      final rightNext = next[rightIndex];

      next[leftIndex] = rightNext;

      if (rightNext >= 0) {
        previous[rightNext] = leftIndex;
      }

      mergeOperations++;
      currentTokenCount--;

      addCandidate(previous[leftIndex]);
      addCandidate(leftIndex);

      if (rule.rank != lastReportedRank) {
        lastReportedRank = rule.rank;

        final currentRule = rule.rank + 1;

        _notifyProgress(
          onProgress: onProgress,
          operation: TokenizerOperation.encoding,
          progress: currentRule / totalRules,
          current: currentRule,
          total: totalRules,
          unit: 'merge rules',
          stage: 'Applying merge rules',
          startedAt: startedAt,
          details: {'currentTokenCount': currentTokenCount, 'mergeOperations': mergeOperations},
        );
      }
    }

    final result = <int>[];

    var index = 0;

    while (index >= 0) {
      if (alive[index] != 0) {
        result.add(tokens[index]);
      }

      index = next[index];
    }

    final finishedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.encoding,
      progress: 1,
      current: totalRules,
      total: totalRules,
      unit: 'merge rules',
      stage: 'Completed',
      startedAt: startedAt,
      finishedAt: finishedAt,
      isCompleted: true,
      details: {'currentTokenCount': result.length, 'mergeOperations': mergeOperations},
    );

    return result;
  }

  @override
  String decode(List<int> tokenIds, {TokenizerProgressCallback? onProgress}) {
    final startedAt = DateTime.now();
    final bytes = <int>[];

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.decoding,
      progress: 0,
      current: 0,
      total: tokenIds.length,
      unit: 'tokens',
      stage: 'Decoding tokens',
      startedAt: startedAt,
    );

    for (var i = 0; i < tokenIds.length; i++) {
      final id = tokenIds[i];

      final token = vocabulary.tokenOf(id);

      if (token == null) {
        throw ArgumentError('Unknown token ID: $id');
      }

      bytes.addAll(token.bytes);

      final current = i + 1;

      _notifyProgress(
        onProgress: onProgress,
        operation: TokenizerOperation.decoding,
        progress: tokenIds.isEmpty ? 1 : current / tokenIds.length,
        current: current,
        total: tokenIds.length,
        unit: 'tokens',
        stage: 'Decoding tokens',
        startedAt: startedAt,
        details: {'decodedBytes': bytes.length},
      );
    }

    final result = utf8.decode(bytes);
    final finishedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.decoding,
      progress: 1,
      current: tokenIds.length,
      total: tokenIds.length,
      unit: 'tokens',
      stage: 'Completed',
      startedAt: startedAt,
      finishedAt: finishedAt,
      isCompleted: true,
      details: {'decodedBytes': bytes.length},
    );

    return result;
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'byte_bpe',
      'name': name,
      if (trainingInfo != null) 'training': trainingInfo!.toJson(),
      'vocabulary': [
        for (final id in vocabulary.ids) {'id': id, 'bytes': vocabulary.tokenOf(id)!.bytes},
      ],
      'merges': [for (final merge in merges) merge.toJson()],
    };
  }

  Future<void> save(String path) async {
    final file = File(path);

    await file.parent.create(recursive: true);

    const encoder = JsonEncoder.withIndent('  ');

    await file.writeAsString(encoder.convert(toJson()));
  }

  static Future<BpeTokenizer> load(String path) {
    return fromFile(path);
  }

  void _notifyProgress({
    required TokenizerProgressCallback? onProgress,
    required TokenizerOperation operation,
    required double progress,
    required DateTime startedAt,
    required int current,
    required int total,
    required String unit,
    required String stage,
    Map<String, Object?> details = const {},
    DateTime? finishedAt,
    bool isCompleted = false,
  }) {
    onProgress?.call(
      TokenizerProgress(
        operation: operation,
        progress: progress.clamp(0.0, 1.0),
        current: current,
        total: total,
        unit: unit,
        stage: stage,
        startedAt: startedAt,
        updatedAt: finishedAt ?? DateTime.now(),
        finishedAt: finishedAt,
        isCompleted: isCompleted,
        details: details,
      ),
    );
  }
}

final class _MergeCandidate {
  const _MergeCandidate({required this.leftIndex, required this.rightIndex, required this.rank});

  final int leftIndex;
  final int rightIndex;
  final int rank;
}

int _compareMergeCandidates(_MergeCandidate a, _MergeCandidate b) {
  final rankComparison = a.rank.compareTo(b.rank);

  if (rankComparison != 0) {
    return rankComparison;
  }

  return a.leftIndex.compareTo(b.leftIndex);
}
