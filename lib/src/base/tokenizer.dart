import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';

abstract interface class Tokenizer {
  String get name;

  int get vocabularySize;

  List<int> encode(String text, {TokenizerProgressCallback? onProgress});

  String decode(List<int> tokenIds, {TokenizerProgressCallback? onProgress});
}
