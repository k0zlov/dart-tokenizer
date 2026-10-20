# Dart Tokenizer

A small Dart package for training, using, inspecting, and evaluating tokenizers.

## Features

- Custom byte-level BPE tokenizer implemented from scratch
- BPE tokenizer training with configurable vocabulary size
- Encoding and decoding with progress reporting
- Save and load trained BPE tokenizers
- Human-readable BPE vocabulary and merge inspection
- Tokenizer evaluation metrics:
    - Tokens per word
    - Bytes per token
    - Characters per token
    - Encoding speed
- `tiktoken` support for comparison with existing tokenizers
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