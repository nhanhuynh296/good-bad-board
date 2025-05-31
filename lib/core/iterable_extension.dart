extension ImmutabilListExtension<E> on Iterable<E> {
  /// Returns an immutable copy of the list.
  List<E> toUnmodifiableList() => List.unmodifiable(this);

  /// Only use when you are changing the element within. Otherwise use toUnmodifiableList
  List<E> toFixedLengthList() => List.of(this, growable: false);
}
