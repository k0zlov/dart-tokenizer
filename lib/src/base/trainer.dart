import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';

abstract interface class TokenizerTrainer<T extends Tokenizer> {
  T train(String corpus, {required String name, required int vocabularySize, TokenizerProgressCallback? onProgress});
}
