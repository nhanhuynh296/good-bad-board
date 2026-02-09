import 'package:flutter/foundation.dart';

abstract class InMemoryRepository<V> extends ChangeNotifier {
  Future<void> add(V value);

  Future<void> delete(String id);

  Future<V?> get(String id);

  Future<Iterable<V>> getAll({int? count, int? offset});

  Future<void> update(String id, V value);
}
