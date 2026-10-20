import 'dart:convert';

import 'package:dart_tokenizer/src/bpe/base/bpe_merge_info.dart';
import 'package:dart_tokenizer/src/bpe/base/bpe_token_info.dart';

final class BpeTokenizerInfo {
  const BpeTokenizerInfo({required this.name, required this.vocabulary, required this.merges});

  final String name;
  final List<BpeTokenInfo> vocabulary;
  final List<BpeMergeInfo> merges;

  @override
  String toString() {
    return 'BpeTokenizerInfo('
        'name: ${jsonEncode(name)}, '
        'vocabulary: $vocabulary, '
        'merges: $merges'
        ')';
  }
}
