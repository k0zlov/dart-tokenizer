enum TiktokenEncoding {
  cl100kBase('cl100k_base'),
  p50kBase('p50k_base'),
  p50kEdit('p50k_edit'),
  r50kBase('r50k_base'),
  gpt2('gpt2');

  const TiktokenEncoding(this.encodingName);

  final String encodingName;

  @override
  String toString() => encodingName;
}
