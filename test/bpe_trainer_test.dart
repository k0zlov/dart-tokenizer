import 'package:dart_tokenizer/src/bpe/trainers/bpe_trainer.dart';
import 'package:test/test.dart';

void main() {
  group('BpeTrainer', () {
    group('training', () {
      test('creates tokenizer with byte-level vocabulary', () {
        const trainer = BpeTrainer();

        final tokenizer = trainer.train('Hello world!', name: 'Test BPE', vocabularySize: 256);

        expect(tokenizer.vocabularySize, 256);
      });

      test('adds tokens to vocabulary during training', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train('aaaaaa', name: 'Test BPE', vocabularySize: 257);

        expect(tokenizer.vocabularySize, 257);
      });

      test('does not exceed target vocabulary size', () {
        const trainer = BpeTrainer(minPairFrequency: 1);

        final tokenizer = trainer.train('banana banana banana banana', name: 'Test BPE', vocabularySize: 260);

        expect(tokenizer.vocabularySize, lessThanOrEqualTo(260));
      });

      test('compresses repeated byte sequences', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train('aaaaaa', name: 'Test BPE', vocabularySize: 257);

        final encoded = tokenizer.encode('aaaaaa');

        expect(encoded.length, lessThan(6));
      });

      test('uses learned merges when encoding new text', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train(
          'Hello world! Hello world! Hello world!',
          name: 'Test BPE',
          vocabularySize: 300,
        );

        final encoded = tokenizer.encode('Hello world!');

        expect(encoded.length, lessThan('Hello world!'.codeUnits.length));
      });

      test('assigns tokenizer name', () {
        const trainer = BpeTrainer();

        final tokenizer = trainer.train('Hello world!', name: 'English BPE', vocabularySize: 256);

        expect(tokenizer.name, 'English BPE');
      });
    });

    group('minimum pair frequency', () {
      test('does not merge pairs below minimum frequency', () {
        const trainer = BpeTrainer(minPairFrequency: 100);

        final tokenizer = trainer.train('Hello world!', name: 'Test BPE', vocabularySize: 300);

        expect(tokenizer.vocabularySize, 256);
      });

      test('merges pairs that reach minimum frequency', () {
        const trainer = BpeTrainer(minPairFrequency: 3);

        final tokenizer = trainer.train('aaaa', name: 'Test BPE', vocabularySize: 257);

        expect(tokenizer.vocabularySize, 257);
      });
    });

    group('round trip', () {
      test('preserves ASCII text after training', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train(
          'Hello world! Hello world! Hello world!',
          name: 'Test BPE',
          vocabularySize: 300,
        );

        const text = 'Hello world!';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });

      test('preserves Ukrainian text after training', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train(
          'Привіт світ! Привіт світ! Привіт світ!',
          name: 'Test BPE',
          vocabularySize: 300,
        );

        const text = 'Привіт світ!';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });

      test('preserves emoji after training', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train('😀🚀😀🚀😀🚀😀🚀', name: 'Test BPE', vocabularySize: 300);

        const text = '😀🚀';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });

      test('preserves mixed multilingual text after training', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        const corpus = 'Hello Привіт 😀 Hello Привіт 😀 Hello Привіт 😀';

        final tokenizer = trainer.train(corpus, name: 'Test BPE', vocabularySize: 320);

        const text = 'Hello Привіт 😀';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });

      test('preserves text not present in training corpus', () {
        const trainer = BpeTrainer(minPairFrequency: 2);

        final tokenizer = trainer.train('hello hello hello hello', name: 'Test BPE', vocabularySize: 300);

        const text = 'Абсолютно інший текст 🚀';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });
    });

    group('empty corpus', () {
      test('keeps base vocabulary for empty corpus', () {
        const trainer = BpeTrainer();

        final tokenizer = trainer.train('', name: 'Test BPE', vocabularySize: 300);

        expect(tokenizer.vocabularySize, 256);
      });

      test('creates tokenizer that can encode text after empty training', () {
        const trainer = BpeTrainer();

        final tokenizer = trainer.train('', name: 'Test BPE', vocabularySize: 300);

        const text = 'Hello 😀';

        expect(tokenizer.decode(tokenizer.encode(text)), text);
      });
    });

    group('validation', () {
      test('throws when vocabulary size is below 256', () {
        const trainer = BpeTrainer();

        expect(() => trainer.train('Hello', name: 'Test BPE', vocabularySize: 255), throwsArgumentError);
      });

      test('throws when minimum pair frequency is below 1', () {
        const trainer = BpeTrainer(minPairFrequency: 0);

        expect(() => trainer.train('Hello', name: 'Test BPE', vocabularySize: 300), throwsArgumentError);
      });
    });
  });
}
