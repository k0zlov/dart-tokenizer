import 'package:dart_tokenizer/src/tiktoken/base/tiktoken_encoding.dart';

enum TiktokenModel {
  gpt4('gpt-4', TiktokenEncoding.cl100kBase),
  gpt35Turbo('gpt-3.5-turbo', TiktokenEncoding.cl100kBase),
  textEmbeddingAda002('text-embedding-ada-002', TiktokenEncoding.cl100kBase),
  textDavinci003('text-davinci-003', TiktokenEncoding.p50kBase),
  textDavinci002('text-davinci-002', TiktokenEncoding.p50kBase),
  codeDavinci002('code-davinci-002', TiktokenEncoding.p50kBase);

  const TiktokenModel(this.modelName, this.encoding);

  final String modelName;
  final TiktokenEncoding encoding;

  @override
  String toString() => modelName;
}
