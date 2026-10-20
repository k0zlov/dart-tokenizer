final class MergeRule {
  const MergeRule({
    required this.leftId,
    required this.rightId,
    required this.resultId,
    required this.rank,
  });

  final int leftId;
  final int rightId;
  final int resultId;
  final int rank;

  Map<String, dynamic> toJson() {
    return {
      'leftId': leftId,
      'rightId': rightId,
      'resultId': resultId,
      'rank': rank,
    };
  }

  factory MergeRule.fromJson(Map<String, dynamic> json) {
    return MergeRule(
      leftId: json['leftId'] as int,
      rightId: json['rightId'] as int,
      resultId: json['resultId'] as int,
      rank: json['rank'] as int,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is MergeRule &&
            leftId == other.leftId &&
            rightId == other.rightId &&
            resultId == other.resultId &&
            rank == other.rank;
  }

  @override
  int get hashCode => Object.hash(
    leftId,
    rightId,
    resultId,
    rank,
  );

  @override
  String toString() {
    return '{$leftId + $rightId -> $resultId, R:$rank}';
  }
}