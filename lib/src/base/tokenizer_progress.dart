enum TokenizerOperation { training, encoding, decoding }

final class TokenizerProgress {
  const TokenizerProgress({
    required this.operation,
    required this.progress,
    required this.startedAt,
    required this.updatedAt,
    required this.isCompleted,
    this.finishedAt,
    this.current,
    this.total,
    this.unit,
    this.stage,
    this.details = const {},
  });

  final TokenizerOperation operation;

  final double progress;

  final int? current;
  final int? total;

  final String? unit;
  final String? stage;

  final bool isCompleted;

  final DateTime startedAt;
  final DateTime updatedAt;
  final DateTime? finishedAt;

  final Map<String, Object?> details;

  double get percentage => progress * 100;

  Duration get elapsed => (finishedAt ?? updatedAt).difference(startedAt);

  double get elapsedSeconds => elapsed.inMicroseconds / Duration.microsecondsPerSecond;
}

typedef TokenizerProgressCallback = void Function(TokenizerProgress progress);
