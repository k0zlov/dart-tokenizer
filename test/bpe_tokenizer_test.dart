import 'package:dart_tokenizer/src/base/tokenizer.dart';
import 'package:dart_tokenizer/src/bpe/base/byte_vocabulary.dart';
import 'package:dart_tokenizer/src/bpe/tokenizers/bpe_tokenizer.dart';
import 'package:test/test.dart';

void main() {
  group('BpeTokenizer', () {
    group('encode', () {
      test('encodes ASCII text into byte token IDs', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        final encoded = tokenizer.encode('Hello world!');

        expect(
          encoded,
          [72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33],
        );
      });

      test('encodes empty text into an empty token list', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        final encoded = tokenizer.encode('');

        expect(encoded, isEmpty);
      });

      test('encodes UTF-8 text into byte token IDs', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        final encoded = tokenizer.encode('Привіт');

        expect(encoded, isNotEmpty);
        expect(encoded.every((id) => id >= 0 && id <= 255), isTrue);
      });
    });

    group('decode', () {
      test('decodes byte token IDs into ASCII text', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        final decoded = tokenizer.decode([
          72,
          101,
          108,
          108,
          111,
          32,
          119,
          111,
          114,
          108,
          100,
          33,
        ]);

        expect(decoded, 'Hello world!');
      });

      test('decodes an empty token list into empty text', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        final decoded = tokenizer.decode([]);

        expect(decoded, '');
      });
    });

    group('round trip', () {
      test('preserves ASCII text', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        const text = 'Hello world!';

        expect(
          tokenizer.decode(tokenizer.encode(text)),
          text,
        );
      });

      test('preserves Ukrainian text', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        const text = 'Привіт, світ!';

        expect(
          tokenizer.decode(tokenizer.encode(text)),
          text,
        );
      });

      test('preserves emoji', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        const text = 'Hello 😀🚀';

        expect(
          tokenizer.decode(tokenizer.encode(text)),
          text,
        );
      });

      test('preserves mixed multilingual text', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        const text = 'Привіт world! 日本 😀';

        expect(
          tokenizer.decode(tokenizer.encode(text)),
          text,
        );
      });
    });

    group('metadata', () {
      test('returns tokenizer name', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        expect(tokenizer.name, 'Custom BPE');
      });

      test('returns byte-level vocabulary size', () {
        final Tokenizer tokenizer = BpeTokenizer(
          vocabulary: ByteVocabulary.byteLevel(),
          merges: [],
        );

        expect(tokenizer.vocabularySize, 256);
      });
    });
  });
}