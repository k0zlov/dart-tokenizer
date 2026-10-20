import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';
import 'package:dart_tokenizer/src/tiktoken/base/tiktoken_encoding.dart';
import 'package:dart_tokenizer/src/tiktoken/base/tiktoken_model.dart';
import 'package:tiktoken/tiktoken.dart' as tiktoken;

final class TiktokenTokenizer implements Tokenizer {
  TiktokenTokenizer.fromEncoding(TiktokenEncoding encoding)
    : encoding = encoding,
      model = null,
      _tiktoken = tiktoken.getEncoding(encoding.encodingName);

  TiktokenTokenizer.fromModel(TiktokenModel model)
    : model = model,
      encoding = model.encoding,
      _tiktoken = tiktoken.encodingForModel(model.modelName);

  final TiktokenEncoding encoding;

  final TiktokenModel? model;

  final tiktoken.Tiktoken _tiktoken;

  String get encodingName => _tiktoken.name;

  @override
  String get name {
    if (model != null) {
      return 'Tiktoken ${model!.modelName}';
    }

    return 'Tiktoken ${encoding.encodingName}';
  }

  @override
  int get vocabularySize {
    return _tiktoken.explicitNVocab ?? _tiktoken.maxTokenValue + 1;
  }

  @override
  List<int> encode(String text, {TokenizerProgressCallback? onProgress}) {
    final startedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.encoding,
      progress: 0,
      stage: 'Encoding',
      startedAt: startedAt,
      details: {'encoding': encoding.encodingName, if (model != null) 'model': model!.modelName},
    );

    final tokens = _tiktoken.encodeOrdinary(text).toList(growable: false);

    final finishedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.encoding,
      progress: 1,
      stage: 'Completed',
      startedAt: startedAt,
      finishedAt: finishedAt,
      isCompleted: true,
      details: {
        'encoding': encoding.encodingName,
        if (model != null) 'model': model!.modelName,
        'tokenCount': tokens.length,
      },
    );

    return tokens;
  }

  @override
  String decode(List<int> tokenIds, {TokenizerProgressCallback? onProgress}) {
    final startedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.decoding,
      progress: 0,
      stage: 'Decoding',
      startedAt: startedAt,
      details: {
        'encoding': encoding.encodingName,
        if (model != null) 'model': model!.modelName,
        'tokenCount': tokenIds.length,
      },
    );

    final text = _tiktoken.decode(tokenIds);

    final finishedAt = DateTime.now();

    _notifyProgress(
      onProgress: onProgress,
      operation: TokenizerOperation.decoding,
      progress: 1,
      stage: 'Completed',
      startedAt: startedAt,
      finishedAt: finishedAt,
      isCompleted: true,
      details: {
        'encoding': encoding.encodingName,
        if (model != null) 'model': model!.modelName,
        'tokenCount': tokenIds.length,
      },
    );

    return text;
  }

  void _notifyProgress({
    required TokenizerProgressCallback? onProgress,
    required TokenizerOperation operation,
    required double progress,
    required String stage,
    required DateTime startedAt,
    DateTime? finishedAt,
    bool isCompleted = false,
    Map<String, Object?> details = const {},
  }) {
    onProgress?.call(
      TokenizerProgress(
        operation: operation,
        progress: progress.clamp(0.0, 1.0),
        current: null,
        total: null,
        unit: null,
        stage: stage,
        isCompleted: isCompleted,
        startedAt: startedAt,
        updatedAt: finishedAt ?? DateTime.now(),
        finishedAt: finishedAt,
        details: details,
      ),
    );
  }
}
