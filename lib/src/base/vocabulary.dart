abstract class Vocabulary<T extends Object> {
  int get length;

  Iterable<int> get ids;

  Iterable<T> get tokens;

  int? idOf(T token);

  T? tokenOf(int id);

  bool containsToken(T token) => idOf(token) != null;

  bool containsId(int id) => tokenOf(id) != null;
}

abstract class MutableVocabulary<T extends Object> extends Vocabulary<T> {
  int add(T token);
}
