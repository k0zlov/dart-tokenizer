import 'dart:typed_data';

import 'package:dart_tokenizer/src/base/vocabulary.dart';

final class ByteVocabulary implements MutableVocabulary<ByteToken> {
  ByteVocabulary();

  factory ByteVocabulary.byteLevel() {
    final vocabulary = ByteVocabulary();

    for (var byte = 0; byte < 256; byte++) {
      vocabulary.add(ByteToken.single(byte));
    }

    return vocabulary;
  }

  factory ByteVocabulary.fromTokenToId(Map<ByteToken, int> tokens) {
    final vocabulary = ByteVocabulary();

    for (final entry in tokens.entries) {
      vocabulary._addWithId(entry.key, entry.value);
    }

    return vocabulary;
  }

  factory ByteVocabulary.fromIdToToken(Map<int, ByteToken> tokens) {
    final vocabulary = ByteVocabulary();

    for (final entry in tokens.entries) {
      vocabulary._addWithId(entry.value, entry.key);
    }

    return vocabulary;
  }

  final Map<ByteToken, int> _tokenToId = {};
  final Map<int, ByteToken> _idToToken = {};

  int _nextId = 0;

  @override
  int get length => _tokenToId.length;

  @override
  Iterable<int> get ids => _idToToken.keys;

  @override
  Iterable<ByteToken> get tokens => _tokenToId.keys;

  @override
  int? idOf(ByteToken token) {
    return _tokenToId[token];
  }

  @override
  ByteToken? tokenOf(int id) {
    return _idToToken[id];
  }

  @override
  bool containsToken(ByteToken token) {
    return _tokenToId.containsKey(token);
  }

  @override
  bool containsId(int id) {
    return _idToToken.containsKey(id);
  }

  @override
  int add(ByteToken token) {
    final existingId = _tokenToId[token];

    if (existingId != null) {
      return existingId;
    }

    while (_idToToken.containsKey(_nextId)) {
      _nextId++;
    }

    final id = _nextId++;

    _tokenToId[token] = id;
    _idToToken[id] = token;

    return id;
  }

  int addBytes(Iterable<int> bytes) {
    return add(ByteToken(bytes));
  }

  int addMerge(ByteToken left, ByteToken right) {
    return add(left.concat(right));
  }

  void _addWithId(ByteToken token, int id) {
    if (id < 0) {
      throw ArgumentError.value(id, 'id', 'Token ID cannot be negative');
    }

    if (_tokenToId.containsKey(token)) {
      throw ArgumentError('Token already exists: $token');
    }

    if (_idToToken.containsKey(id)) {
      throw ArgumentError('Token ID already exists: $id');
    }

    _tokenToId[token] = id;
    _idToToken[id] = token;

    if (id >= _nextId) {
      _nextId = id + 1;
    }
  }
}

final class ByteToken {
  ByteToken(Iterable<int> bytes) : _bytes = _createBytes(bytes);

  factory ByteToken.single(int byte) {
    return ByteToken([byte]);
  }

  final Uint8List _bytes;

  static Uint8List _createBytes(Iterable<int> bytes) {
    final values = bytes.toList(growable: false);

    for (final byte in values) {
      if (byte < 0 || byte > 255) {
        throw ArgumentError.value(byte, 'byte', 'Byte value must be between 0 and 255');
      }
    }

    return Uint8List.fromList(values);
  }

  List<int> get bytes => List.unmodifiable(_bytes);

  int get length => _bytes.length;

  ByteToken concat(ByteToken other) {
    return ByteToken([..._bytes, ...other._bytes]);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! ByteToken) {
      return false;
    }

    if (_bytes.length != other._bytes.length) {
      return false;
    }

    for (var i = 0; i < _bytes.length; i++) {
      if (_bytes[i] != other._bytes[i]) {
        return false;
      }
    }

    return true;
  }

  @override
  int get hashCode => Object.hashAll(_bytes);

  @override
  String toString() => 'ByteToken(${_bytes.toList()})';
}
