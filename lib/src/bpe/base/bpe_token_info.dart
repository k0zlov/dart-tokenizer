import 'dart:convert';

final class BpeTokenInfo {
  const BpeTokenInfo({
    required this.id,
    required this.bytes,
    required this.text,
    required this.hex,
    required this.isValidUtf8,
  });

  final int id;
  final List<int> bytes;
  final String? text;
  final String hex;
  final bool isValidUtf8;

  @override
  String toString() {
    return '('
        'id:$id, '
        'b:$bytes, '
        't:${text == null ? 'null' : jsonEncode(text)}, '
        'h:$hex, '
        'u8:$isValidUtf8'
        ')';
  }
}
