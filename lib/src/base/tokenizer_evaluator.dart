import 'dart:convert';

import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/base/tokenizer_metrics.dart';

final class TokenizerEvaluator {
  const TokenizerEvaluator();

  TokenizerMetrics evaluate(Tokenizer tokenizer, String text) {
    final characters = text.runes.length;
    final bytes = utf8.encode(text).length;
    final words = _countWords(text);

    final stopwatch = Stopwatch()..start();
    final tokenIds = tokenizer.encode(text);
    stopwatch.stop();

    final tokens = tokenIds.length;

    return TokenizerMetrics(
      characters: characters,
      bytes: bytes,
      words: words,
      tokens: tokens,
      tokensPerWord: words == 0 ? 0 : tokens / words,
      bytesPerToken: tokens == 0 ? 0 : bytes / tokens,
      charactersPerToken: tokens == 0 ? 0 : characters / tokens,
      charactersPerSecond: stopwatch.elapsedMicroseconds == 0
          ? 0
          : characters / (stopwatch.elapsedMicroseconds / Duration.microsecondsPerSecond),
    );
  }

  int _countWords(String text) {
    return RegExp(r'\S+', unicode: true).allMatches(text).length;
  }
}
