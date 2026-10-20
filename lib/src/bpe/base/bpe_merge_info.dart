import 'package:dart_tokenizer/src/bpe/base/bpe_token_info.dart';

final class BpeMergeInfo {
  const BpeMergeInfo({required this.rank, required this.left, required this.right, required this.result});

  final int rank;
  final BpeTokenInfo left;
  final BpeTokenInfo right;
  final BpeTokenInfo result;

  @override
  String toString() {
    return '('
        'rk:$rank, '
        'l:$left, '
        'r:$right, '
        'res:$result'
        ')';
  }
}
