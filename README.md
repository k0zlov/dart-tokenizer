# Dart Tokenizer

A small Dart package for training, using, inspecting, and evaluating tokenizers.

## Features

- Custom byte-level BPE tokenizer implemented from scratch
- Configurable BPE vocabulary size
- Encoding and decoding with progress reporting
- Save and load trained BPE tokenizers
- Human-readable BPE vocabulary and merge inspection
- Tokenizer evaluation metrics
- Tiktoken support for comparison
- Common `Tokenizer` interface for different implementations
- CLI tools for training and evaluation

## Usage

```dart
import 'package:dart_tokenizer/dart_tokenizer.dart';

final trainer = BpeTrainer();

final tokenizer = trainer.train(
  corpus,
  name: 'Custom BPE',
  vocabularySize: 8000,
);

final tokens = tokenizer.encode('Hello world!');
final decoded = tokenizer.decode(tokens);
```

Tiktoken can be used through the same interface:

```dart
final tokenizer = TiktokenTokenizer.fromEncoding(
  TiktokenEncoding.cl100kBase,
);
```

## CLI

Train a tokenizer:

```bash
dart run bin/dart_tokenizer.dart train \
  -i data/input/corpus.txt \
  -o data/output/tokenizer.json \
  --vocab-size 8000
```

Evaluate a trained tokenizer:

```bash
dart run bin/dart_tokenizer.dart encode \
  -t data/output/tokenizer.json \
  -i data/input/validation.txt
```

Evaluate with Tiktoken:

```bash
dart run bin/dart_tokenizer.dart encode \
  --tiktoken-encoding cl100k_base \
  -i data/input/validation.txt
```

## Requirements

- Dart SDK
- `tiktoken`

## License

For educational use.
