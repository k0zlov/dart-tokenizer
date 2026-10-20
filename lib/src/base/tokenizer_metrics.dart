final class TokenizerMetrics {
  const TokenizerMetrics({
    required this.characters,
    required this.bytes,
    required this.words,
    required this.tokens,
    required this.tokensPerWord,
    required this.bytesPerToken,
    required this.charactersPerToken,
    required this.charactersPerSecond,
  });

  final int characters;
  final int bytes;
  final int words;
  final int tokens;

  final double tokensPerWord;
  final double bytesPerToken;
  final double charactersPerToken;

  final double charactersPerSecond;
}
