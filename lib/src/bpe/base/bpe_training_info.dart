final class BpeTrainingInfo {
  const BpeTrainingInfo({
    required this.targetVocabularySize,
    required this.actualVocabularySize,
    required this.minPairFrequency,
    required this.corpusCharacters,
    required this.corpusBytes,
    required this.trainingDuration,
    required this.mergesCount,
  });

  final int targetVocabularySize;
  final int actualVocabularySize;
  final int minPairFrequency;

  final int corpusCharacters;
  final int corpusBytes;

  final Duration trainingDuration;

  final int mergesCount;

  Map<String, dynamic> toJson() {
    return {
      'targetVocabularySize': targetVocabularySize,
      'actualVocabularySize': actualVocabularySize,
      'minPairFrequency': minPairFrequency,
      'corpusCharacters': corpusCharacters,
      'corpusBytes': corpusBytes,
      'trainingDurationMs': trainingDuration.inMilliseconds,
      'mergesCount': mergesCount,
    };
  }

  factory BpeTrainingInfo.fromJson(Map<String, dynamic> json) {
    return BpeTrainingInfo(
      targetVocabularySize: json['targetVocabularySize'] as int,
      actualVocabularySize: json['actualVocabularySize'] as int,
      minPairFrequency: json['minPairFrequency'] as int,
      corpusCharacters: json['corpusCharacters'] as int,
      corpusBytes: json['corpusBytes'] as int,
      trainingDuration: Duration(milliseconds: json['trainingDurationMs'] as int),
      mergesCount: json['mergesCount'] as int,
    );
  }
}
