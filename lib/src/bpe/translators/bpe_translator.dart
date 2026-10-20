import 'dart:convert';

import 'package:dart_tokenizer/src/bpe/base/bpe_merge_info.dart';
import 'package:dart_tokenizer/src/bpe/base/bpe_token_info.dart';
import 'package:dart_tokenizer/src/bpe/base/bpe_tokenizer_info.dart';
import 'package:dart_tokenizer/src/bpe/base/byte_vocabulary.dart';
import 'package:dart_tokenizer/src/bpe/tokenizers/bpe_tokenizer.dart';

final class BpeTokenizerTranslator {
  const BpeTokenizerTranslator();

  BpeTokenizerInfo translate(BpeTokenizer tokenizer) {
    final tokenCache = <int, BpeTokenInfo>{};

    BpeTokenInfo tokenInfo(int id) {
      return tokenCache.putIfAbsent(id, () {
        final token = tokenizer.vocabulary.tokenOf(id);

        if (token == null) {
          throw StateError('Unknown token ID: $id');
        }

        return _translateToken(id, token);
      });
    }

    final vocabularyIds = tokenizer.vocabulary.ids.toList()..sort();

    final vocabulary = [for (final id in vocabularyIds) tokenInfo(id)];

    final merges = [
      for (final rule in tokenizer.merges)
        BpeMergeInfo(
          rank: rule.rank,
          left: tokenInfo(rule.leftId),
          right: tokenInfo(rule.rightId),
          result: tokenInfo(rule.resultId),
        ),
    ];

    return BpeTokenizerInfo(
      name: tokenizer.name,
      vocabulary: List.unmodifiable(vocabulary),
      merges: List.unmodifiable(merges),
    );
  }

  BpeTokenInfo _translateToken(int id, ByteToken token) {
    final bytes = token.bytes.toList(growable: false);

    String? text;

    try {
      text = utf8.decode(bytes, allowMalformed: false);
    } on FormatException {
      text = null;
    }

    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');

    return BpeTokenInfo(id: id, bytes: List.unmodifiable(bytes), text: text, hex: hex, isValidUtf8: text != null);
  }
}
