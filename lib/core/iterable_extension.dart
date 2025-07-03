import 'package:collection/collection.dart';

extension ImmutabilListExtension<E> on Iterable<E> {
  /// Returns an immutable copy of the list.
  List<E> toUnmodifiableList() => List.unmodifiable(this);

  /// Only use when you are changing the element within. Otherwise use toUnmodifiableList
  List<E> toFixedLengthList() => List.of(this, growable: false);
}

extension IterableExtension<E> on Iterable<E> {
  (Iterable<E>, int)? mostPopular() {
    if (isEmpty) return null;

    final counts = <E, int>{};
    for (var n in this) {
      counts.update(n, (value) => value + 1, ifAbsent: () => 1);
    }

    final mostPopularValue = counts.values.max;
    final keyMatched = counts.keys.where(
      (key) => counts[key] == mostPopularValue,
    );
    return (keyMatched, mostPopularValue);
  }
}
