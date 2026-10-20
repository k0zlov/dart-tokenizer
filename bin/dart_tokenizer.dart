import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/base/tokenizer_evaluator.dart';
import 'package:dart_tokenizer/src/base/tokenizer_metrics.dart';
import 'package:dart_tokenizer/src/base/tokenizer_progress.dart';
import 'package:dart_tokenizer/src/bpe/tokenizers/bpe_tokenizer.dart';
import 'package:dart_tokenizer/src/bpe/trainers/bpe_trainer.dart';
import 'package:dart_tokenizer/src/tiktoken/base/tiktoken_encoding.dart';
import 'package:dart_tokenizer/src/tiktoken/base/tiktoken_model.dart';
import 'package:dart_tokenizer/src/tiktoken/tokenizers/tiktoken_tokenizer.dart';

Future<void> main(List<String> arguments) async {
  final trainParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message.')
    ..addOption('input', abbr: 'i', mandatory: true, help: 'Path to the input corpus TXT file.', valueHelp: 'file')
    ..addOption(
      'output',
      abbr: 'o',
      mandatory: true,
      help: 'Path where the trained tokenizer will be saved.',
      valueHelp: 'file',
    )
    ..addOption('name', abbr: 'n', defaultsTo: 'Custom BPE', help: 'Name of the tokenizer.', valueHelp: 'name')
    ..addOption('vocab-size', defaultsTo: '8000', help: 'Target vocabulary size.', valueHelp: 'size')
    ..addOption(
      'min-frequency',
      defaultsTo: '2',
      help: 'Minimum frequency required for a token pair to be merged.',
      valueHelp: 'frequency',
    );

  final encodeParser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message.')
    ..addOption('tokenizer', abbr: 't', help: 'Path to a saved custom BPE tokenizer file.', valueHelp: 'file')
    ..addOption(
      'tiktoken-encoding',
      help:
          'Use a Tiktoken encoding. '
          'Available: ${TiktokenEncoding.values.map((e) => e.encodingName).join(', ')}',
      valueHelp: 'encoding',
    )
    ..addOption(
      'tiktoken-model',
      help:
          'Use the Tiktoken encoding for a model. '
          'Available: ${TiktokenModel.values.map((e) => e.modelName).join(', ')}',
      valueHelp: 'model',
    )
    ..addOption('text', help: 'Text to encode.', valueHelp: 'text')
    ..addOption('input', abbr: 'i', help: 'Path to a text file to encode.', valueHelp: 'file')
    ..addOption('output', abbr: 'o', help: 'Path where the full encoding report will be saved.', valueHelp: 'file');

  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help message.')
    ..addCommand('train', trainParser)
    ..addCommand('encode', encodeParser);

  ArgResults args;

  try {
    args = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    stderr.writeln();
    stderr.writeln(_rootHelp(parser));

    exitCode = 64;
    return;
  }

  if (args['help'] == true || args.command == null) {
    stdout.writeln(_rootHelp(parser));

    return;
  }

  try {
    switch (args.command!.name) {
      case 'train':
        await _runTrain(args.command!, trainParser);

      case 'encode':
        await _runEncode(args.command!, encodeParser);
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);

    exitCode = 64;
  }
}

Future<void> _runTrain(ArgResults args, ArgParser parser) async {
  if (args['help'] == true) {
    stdout.writeln('Train a byte-level BPE tokenizer.');

    stdout.writeln();

    stdout.writeln('Usage:');

    stdout.writeln(
      '  dart run bin/dart_tokenizer.dart train '
      '--input <file> '
      '--output <file> '
      '[options]',
    );

    stdout.writeln();

    stdout.writeln('Options:');

    stdout.writeln(parser.usage);

    return;
  }

  final inputPath = args['input'] as String;

  final outputPath = args['output'] as String;

  final name = args['name'] as String;

  final vocabularySize = int.parse(args['vocab-size'] as String);

  final minPairFrequency = int.parse(args['min-frequency'] as String);

  final corpus = await File(inputPath).readAsString();

  final progressPrinter = _ProgressPrinter();

  TokenizerProgress? completedProgress;

  final trainer = BpeTrainer(minPairFrequency: minPairFrequency);

  final tokenizer = trainer.train(
    corpus,
    name: name,
    vocabularySize: vocabularySize,
    onProgress: (progress) {
      progressPrinter.write(progress);

      if (progress.isCompleted) {
        completedProgress = progress;
      }
    },
  );

  progressPrinter.finish();

  await tokenizer.save(outputPath);

  stdout.writeln();

  if (completedProgress != null) {
    stdout.writeln(
      'Started at: '
      '${_formatDateTime(completedProgress!.startedAt)}',
    );

    stdout.writeln(
      'Finished at: '
      '${_formatDateTime(completedProgress!.finishedAt!)}',
    );

    stdout.writeln(
      'Training time: '
      '${completedProgress!.elapsedSeconds.toStringAsFixed(2)}s',
    );
  }

  stdout.writeln();

  stdout.writeln('Tokenizer trained successfully');

  stdout.writeln('Name: ${tokenizer.name}');

  stdout.writeln('Vocabulary size: ${tokenizer.vocabularySize}');

  stdout.writeln('Saved to: $outputPath');
}

Future<void> _runEncode(ArgResults args, ArgParser parser) async {
  if (args['help'] == true) {
    stdout.writeln('Encode, decode and evaluate text using a tokenizer.');

    stdout.writeln();

    stdout.writeln('Usage:');

    stdout.writeln(
      '  dart run bin/dart_tokenizer.dart encode '
      '<tokenizer source> '
      '(--text <text> | --input <file>) '
      '[--output <file>]',
    );

    stdout.writeln();

    stdout.writeln('Tokenizer source:');

    stdout.writeln('  --tokenizer <file>');

    stdout.writeln('  --tiktoken-encoding <encoding>');

    stdout.writeln('  --tiktoken-model <model>');

    stdout.writeln();

    stdout.writeln('Exactly one tokenizer source must be provided.');

    stdout.writeln();

    stdout.writeln('Options:');

    stdout.writeln(parser.usage);

    return;
  }

  final tokenizerPath = args['tokenizer'] as String?;

  final tiktokenEncodingName = args['tiktoken-encoding'] as String?;

  final tiktokenModelName = args['tiktoken-model'] as String?;

  final text = args['text'] as String?;

  final inputPath = args['input'] as String?;

  final outputPath = args['output'] as String?;

  final tokenizerSourceCount = [
    tokenizerPath,
    tiktokenEncodingName,
    tiktokenModelName,
  ].where((value) => value != null).length;

  if (tokenizerSourceCount == 0) {
    stderr.writeln(
      'A tokenizer source must be provided: '
      '--tokenizer, '
      '--tiktoken-encoding or '
      '--tiktoken-model.',
    );

    exitCode = 64;
    return;
  }

  if (tokenizerSourceCount > 1) {
    stderr.writeln('Only one tokenizer source can be provided.');

    exitCode = 64;
    return;
  }

  if (text == null && inputPath == null) {
    stderr.writeln('Either --text or --input must be provided.');

    exitCode = 64;
    return;
  }

  if (text != null && inputPath != null) {
    stderr.writeln('Only one of --text or --input can be provided.');

    exitCode = 64;
    return;
  }

  final tokenizer = await _loadTokenizer(
    tokenizerPath: tokenizerPath,
    tiktokenEncodingName: tiktokenEncodingName,
    tiktokenModelName: tiktokenModelName,
  );

  final input =
      text ??
          await File(
            inputPath!,
          ).readAsString();

  final encodingPrinter = _ProgressPrinter();

  TokenizerProgress? encodingProgress;

  final encoded = tokenizer.encode(
    input,
    onProgress: (progress) {
      encodingPrinter.write(progress);

      if (progress.isCompleted) {
        encodingProgress = progress;
      }
    },
  );

  encodingPrinter.finish();

  final decodingPrinter = _ProgressPrinter();

  TokenizerProgress? decodingProgress;

  final decoded = tokenizer.decode(
    encoded,
    onProgress: (progress) {
      decodingPrinter.write(progress);

      if (progress.isCompleted) {
        decodingProgress = progress;
      }
    },
  );

  decodingPrinter.finish();

  const evaluator = TokenizerEvaluator();

  final metrics = evaluator.evaluate(tokenizer, input);

  final report = _buildEncodeReport(
    tokenizer: tokenizer,
    tokenizerPath: tokenizerPath,
    inputPath: inputPath,
    input: input,
    encoded: encoded,
    decoded: decoded,
    metrics: metrics,
    encodingProgress: encodingProgress,
    decodingProgress: decodingProgress,
  );

  stdout.writeln();

  stdout.write(report);

  if (outputPath != null) {
    final outputFile = File(outputPath);

    await outputFile.parent.create(recursive: true);

    await outputFile.writeAsString(report);

    stdout.writeln();

    stdout.writeln('Report saved to: $outputPath');
  }
}

Future<Tokenizer> _loadTokenizer({
  required String? tokenizerPath,
  required String? tiktokenEncodingName,
  required String? tiktokenModelName,
}) async {
  if (tokenizerPath != null) {
    return BpeTokenizer.fromFile(tokenizerPath);
  }

  if (tiktokenEncodingName != null) {
    final encoding = _parseTiktokenEncoding(tiktokenEncodingName);

    return TiktokenTokenizer.fromEncoding(encoding);
  }

  if (tiktokenModelName != null) {
    final model = _parseTiktokenModel(tiktokenModelName);

    return TiktokenTokenizer.fromModel(model);
  }

  throw StateError('Tokenizer source was not provided.');
}

TiktokenEncoding _parseTiktokenEncoding(String value) {
  for (final encoding in TiktokenEncoding.values) {
    if (encoding.encodingName == value || encoding.name == value) {
      return encoding;
    }
  }

  throw FormatException(
    'Unknown Tiktoken encoding: $value\n'
    'Available encodings: '
    '${TiktokenEncoding.values.map((e) => e.encodingName).join(', ')}',
  );
}

TiktokenModel _parseTiktokenModel(String value) {
  for (final model in TiktokenModel.values) {
    if (model.modelName == value || model.name == value) {
      return model;
    }
  }

  throw FormatException(
    'Unknown Tiktoken model: $value\n'
    'Available models: '
    '${TiktokenModel.values.map((e) => e.modelName).join(', ')}',
  );
}

String _buildEncodeReport({
  required Tokenizer tokenizer,
  required String? tokenizerPath,
  required String? inputPath,
  required String input,
  required List<int> encoded,
  required String decoded,
  required TokenizerMetrics metrics,
  required TokenizerProgress? encodingProgress,
  required TokenizerProgress? decodingProgress,
}) {
  final buffer = StringBuffer();

  buffer.writeln('Dart Tokenizer Report');

  buffer.writeln('=====================');

  buffer.writeln();

  buffer.writeln('Tokenizer');

  buffer.writeln('---------');

  buffer.writeln('Name: ${tokenizer.name}');

  buffer.writeln('Vocabulary size: ${tokenizer.vocabularySize}');

  if (tokenizer is BpeTokenizer) {
    buffer.writeln('Type: Custom byte-level BPE');

    if (tokenizerPath != null) {
      buffer.writeln('File: $tokenizerPath');
    }

    buffer.writeln('Merge rules: ${tokenizer.merges.length}');

    final trainingInfo = tokenizer.trainingInfo;

    if (trainingInfo != null) {
      buffer.writeln();

      buffer.writeln('Training');

      buffer.writeln('--------');

      buffer.writeln(
        'Target vocabulary size: '
        '${trainingInfo.targetVocabularySize}',
      );

      buffer.writeln(
        'Actual vocabulary size: '
        '${trainingInfo.actualVocabularySize}',
      );

      buffer.writeln(
        'Minimum pair frequency: '
        '${trainingInfo.minPairFrequency}',
      );

      buffer.writeln(
        'Corpus characters: '
        '${trainingInfo.corpusCharacters}',
      );

      buffer.writeln(
        'Corpus bytes: '
        '${trainingInfo.corpusBytes}',
      );

      buffer.writeln(
        'Merges completed: '
        '${trainingInfo.mergesCount}',
      );

      buffer.writeln(
        'Training duration: '
        '${_formatDuration(trainingInfo.trainingDuration)}',
      );
    }
  } else if (tokenizer is TiktokenTokenizer) {
    buffer.writeln('Type: Tiktoken');

    buffer.writeln('Encoding: ${tokenizer.encoding.encodingName}');

    if (tokenizer.model != null) {
      buffer.writeln('Model: ${tokenizer.model!.modelName}');
    }
  }

  buffer.writeln();

  buffer.writeln('Input');

  buffer.writeln('-----');

  if (inputPath != null) {
    buffer.writeln('Source: file');

    buffer.writeln('File: $inputPath');
  } else {
    buffer.writeln('Source: command line');
  }

  buffer.writeln('Characters: ${metrics.characters}');

  buffer.writeln('Bytes: ${metrics.bytes}');

  buffer.writeln('Words: ${metrics.words}');

  buffer.writeln();

  buffer.writeln('Text:');

  buffer.writeln(_truncateText(input, 300));

  buffer.writeln();

  buffer.writeln('Encoding');

  buffer.writeln('--------');

  buffer.writeln('Token count: ${metrics.tokens}');

  if (encodingProgress != null) {
    buffer.writeln(
      'Started at: '
      '${_formatDateTime(encodingProgress.startedAt)}',
    );

    buffer.writeln(
      'Finished at: '
      '${_formatDateTime(encodingProgress.finishedAt!)}',
    );

    buffer.writeln(
      'Duration: '
      '${encodingProgress.elapsedSeconds.toStringAsFixed(4)}s',
    );
  }

  buffer.writeln('Token IDs:');

  buffer.writeln(_formatTokenIds(encoded, 300));

  buffer.writeln();

  buffer.writeln('Metrics');

  buffer.writeln('-------');

  buffer.writeln(
    'Tokens per word: '
    '${metrics.tokensPerWord.toStringAsFixed(4)}',
  );

  buffer.writeln(
    'Bytes per token: '
    '${metrics.bytesPerToken.toStringAsFixed(4)}',
  );

  buffer.writeln(
    'Characters per token: '
    '${metrics.charactersPerToken.toStringAsFixed(4)}',
  );

  buffer.writeln(
    'Characters per second: '
    '${metrics.charactersPerSecond.toStringAsFixed(2)}',
  );

  buffer.writeln();

  buffer.writeln('Decoding');

  buffer.writeln('--------');

  if (decodingProgress != null) {
    buffer.writeln(
      'Started at: '
      '${_formatDateTime(decodingProgress.startedAt)}',
    );

    buffer.writeln(
      'Finished at: '
      '${_formatDateTime(decodingProgress.finishedAt!)}',
    );

    buffer.writeln(
      'Duration: '
      '${decodingProgress.elapsedSeconds.toStringAsFixed(4)}s',
    );
  }

  buffer.writeln();

  buffer.writeln(
    'Round trip: '
    '${decoded == input ? 'OK' : 'FAILED'}',
  );

  return buffer.toString();
}

final class _ProgressPrinter {
  _ProgressPrinter() : interval = const Duration(milliseconds: 100);

  final Duration interval;

  DateTime? _lastPrintedAt;

  bool _hasPrinted = false;

  void write(TokenizerProgress progress) {
    final now = DateTime.now();

    if (!progress.isCompleted && _lastPrintedAt != null && now.difference(_lastPrintedAt!) < interval) {
      return;
    }

    _lastPrintedAt = now;
    _hasPrinted = true;

    final operation = _operationName(progress.operation);

    final current = progress.current;

    final total = progress.total;

    final progressText = '${progress.percentage.toStringAsFixed(1)}%';

    final counterText = current != null && total != null
        ? ' ($current/$total'
              '${_unitSuffix(progress.unit)})'
        : '';

    stdout.write(
      '\r$operation: '
      '$progressText'
      '$counterText '
      '${progress.elapsedSeconds.toStringAsFixed(2)}s',
    );
  }

  void finish() {
    if (_hasPrinted) {
      stdout.writeln();
    }

    _lastPrintedAt = null;
    _hasPrinted = false;
  }
}

String _operationName(TokenizerOperation operation) {
  switch (operation) {
    case TokenizerOperation.training:
      return 'Training';

    case TokenizerOperation.encoding:
      return 'Encoding';

    case TokenizerOperation.decoding:
      return 'Decoding';
  }
}

String _unitSuffix(String? unit) {
  if (unit == null || unit.isEmpty) {
    return '';
  }

  return ' $unit';
}

String _formatDuration(Duration duration) {
  final seconds = duration.inMicroseconds / Duration.microsecondsPerSecond;

  return '${seconds.toStringAsFixed(3)}s';
}

String _formatDateTime(DateTime value) {
  String two(int value) {
    return value.toString().padLeft(2, '0');
  }

  String three(int value) {
    return value.toString().padLeft(3, '0');
  }

  return '${value.year}-'
      '${two(value.month)}-'
      '${two(value.day)} '
      '${two(value.hour)}:'
      '${two(value.minute)}:'
      '${two(value.second)}.'
      '${three(value.millisecond)}';
}

String _truncateText(String text, int maxCharacters) {
  final runes = text.runes.toList();

  if (runes.length <= maxCharacters) {
    return text;
  }

  return '${String.fromCharCodes(runes.take(maxCharacters))}...';
}

String _formatTokenIds(List<int> tokenIds, int maxTokens) {
  if (tokenIds.length <= maxTokens) {
    return tokenIds.toString();
  }

  return '[${tokenIds.take(maxTokens).join(', ')}, ...]';
}

String _rootHelp(ArgParser parser) {
  return '''
Dart Tokenizer CLI

Usage:
  dart run bin/dart_tokenizer.dart <command> [options]

Commands:
  train    Train and save a custom byte-level BPE tokenizer.
  encode   Encode, decode and evaluate text using a tokenizer.

Tokenizer types supported by encode:
  Custom BPE
  Tiktoken encoding
  Tiktoken model

Options:
${parser.usage}

Run "<command> --help" for more information.
''';
}
