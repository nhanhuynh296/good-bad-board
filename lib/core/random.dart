import 'dart:math';

import 'package:collection/collection.dart';

extension Picker<E> on List<E> {
  List<E> choices(
    List<double> weights, {
    int count = 1,
    bool replace = false,
    Random? random,
  }) {
    assert(
      weights.length == length,
      'List and weights must be of the same length.',
    );
    assert(count >= 0);
    if (!replace) {
      assert(
        count <= length,
        'Can not pick number of elements more than a list, maximum of $length.',
      );
    }

    final availableWeights = List<double>.of(weights);

    final rng = random ?? Random();
    final pickedElements = <E>[];

    final availableElements = List<E>.of(this);
    for (var i = 0; i < count; i++) {
      final normalizedWeights = availableWeights
          .map((weight) => weight / availableWeights.sum)
          .toList();

      final randomValue = rng.nextDouble();
      double cumulativeWeight = 0.0;

      for (var j = 0; j < availableElements.length; j++) {
        cumulativeWeight += normalizedWeights[j];
        if (randomValue > cumulativeWeight) {
          continue;
        }
        pickedElements.add(availableElements[j]);
        if (!replace) {
          availableElements.removeAt(j);
          availableWeights.removeAt(j);
        }
        break;
      }
    }

    return pickedElements;
  }
}
