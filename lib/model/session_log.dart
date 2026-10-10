import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/game.dart';
import 'package:uuid/uuid.dart';

part 'session_log.freezed.dart';
part 'session_log.g.dart';

@Freezed(equal: false, copyWith: false, addImplicitFinal: true)
abstract class SessionLog with _$SessionLog {
  const SessionLog._();

  factory SessionLog({
    required String id,
    required DateTime loggedAt,
    required int capacity,
    required int checkedInCount,
    required int waitlistCount,
    required int rerollCount,
    required List<int> courtLevelGaps,
    required int courtCount,
  }) = _SessionLog;

  factory SessionLog.create({
    required int capacity,
    required int checkedInCount,
    required int waitlistCount,
    required int rerollCount,
    required List<int> courtLevelGaps,
    required int courtCount,
  }) => SessionLog(
    id: const Uuid().v4(),
    loggedAt: DateTime.now(),
    capacity: capacity,
    checkedInCount: checkedInCount,
    waitlistCount: waitlistCount,
    rerollCount: rerollCount,
    courtLevelGaps: courtLevelGaps,
    courtCount: courtCount,
  );

  /// Fraction of the theoretical max capacity (courtCount * 4) that was
  /// actually filled by checked-in players.
  double get fillRate {
    final maxSlots = courtCount * Game.playerPerCourt;
    if (maxSlots <= 0) return 0;
    return (checkedInCount / maxSlots).clamp(0, 1);
  }

  /// Average level gap across all courts, expressed in tier-index units.
  double get averageLevelGap =>
      courtLevelGaps.isEmpty ? 0 : courtLevelGaps.average;

  /// Number of unfilled court slots (never negative).
  int get idleCourtSlots =>
      (courtCount * Game.playerPerCourt) -
      checkedInCount.clamp(0, courtCount * Game.playerPerCourt);

  // Json Serialization
  factory SessionLog.fromJson(Map<String, dynamic> json) =>
      _$SessionLogFromJson(json);
}
