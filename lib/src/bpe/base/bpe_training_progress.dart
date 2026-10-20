final class BpeTrainingProgress {
  const BpeTrainingProgress({
    required this.progress,
    required this.currentVocabularySize,
    required this.targetVocabularySize,
    required this.mergesCompleted,
    required this.currentTokenCount,
    required this.isCompleted,
    required this.startedAt,
    required this.updatedAt,
    this.finishedAt,
  });

  final double progress;
  final int currentVocabularySize;
  final int targetVocabularySize;
  final int mergesCompleted;
  final int currentTokenCount;
  final bool isCompleted;

  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  double get percentage => progress * 100;

  Duration get elapsed => (finishedAt ?? updatedAt).difference(startedAt);

  double get elapsedSeconds => elapsed.inMilliseconds / 1000;
}

typedef BpeTrainingProgressCallback = void Function(BpeTrainingProgress progress);
