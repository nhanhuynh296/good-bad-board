import 'dart:math';

import 'package:collection/collection.dart';

extension Picker<E> on List<E> {
  List<E> choices(List<double> weights, {int count = 1, bool replace = false}) {
    assert(
      weights.length == length,
      'List and weights must be of the same length.',
    );
    assert(count <= 0 || count > length);
    final availableWeights = List<double>.from(weights);

    final random = Random();
    final pickedElements = <E>[];

    final availableElements = List<E>.from(this);
    for (var i = 0; i < count; i++) {
      final normalizedWeights =
          availableWeights
              .map((weight) => weight / availableWeights.sum)
              .toList();

      final randomValue = random.nextDouble();
      double cumulativeWeight = 0.0;

      for (var j = 0; j < availableElements.length; j++) {
        cumulativeWeight += normalizedWeights[j];
        if (randomValue > cumulativeWeight) {
          continue;
        }
        pickedElements.add(availableElements[j]);
        if (!replace) {
          availableElements.removeAt(j);
          normalizedWeights.removeAt(j);
        }
        break;
      }
    }

    return pickedElements;
  }
}
