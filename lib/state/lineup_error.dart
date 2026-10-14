import 'package:collection/collection.dart';

/// Why [GameData] refused a lineup action.
///
/// Carries data only, no UI text. The Dashboard maps each case to an ARB
/// message (R45-02).
sealed class LineupError implements Exception {
  const LineupError();
}

/// Generate was pressed with no courts.
final class NoCourts extends LineupError {
  const NoCourts();

  @override
  bool operator ==(Object other) => other is NoCourts;

  @override
  int get hashCode => (NoCourts).hashCode;
}

/// Generate was pressed with fewer than one court of checked-in players.
final class NotEnoughPlayers extends LineupError {
  const NotEnoughPlayers({required this.count});

  /// The number of checked-in players.
  final int count;

  @override
  bool operator ==(Object other) =>
      other is NotEnoughPlayers && other.count == count;

  @override
  int get hashCode => Object.hash(NotEnoughPlayers, count);

  @override
  String toString() => 'NotEnoughPlayers(count: $count)';
}

/// Save was pressed with one or more courts that do not have a full lineup.
final class UnbalancedCourts extends LineupError {
  const UnbalancedCourts({required this.courtNumbers});

  /// The 1-based numbers of the courts that are not full.
  final List<int> courtNumbers;

  @override
  bool operator ==(Object other) =>
      other is UnbalancedCourts &&
      const ListEquality<int>().equals(other.courtNumbers, courtNumbers);

  @override
  int get hashCode =>
      Object.hash(UnbalancedCourts, Object.hashAll(courtNumbers));

  @override
  String toString() => 'UnbalancedCourts(courtNumbers: $courtNumbers)';
}

/// Save was pressed with no players on any court.
final class NothingToSave extends LineupError {
  const NothingToSave();

  @override
  bool operator ==(Object other) => other is NothingToSave;

  @override
  int get hashCode => (NothingToSave).hashCode;
}
