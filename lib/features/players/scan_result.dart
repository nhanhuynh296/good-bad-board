import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';

/// The 9 states of the scan result box (IMPLEMENTATION 8.7.2, UAT PLY-16).
enum ScanKind {
  /// Before the first scan.
  ready,

  /// The scan checked the player in (PLY-17).
  checkedIn,

  /// The scan checked the player out (PLY-18).
  checkedOut,

  /// The same target as the last scan check-in; nothing changed (PLY-19).
  scannedTwice,

  /// No ID equals the text and the list is empty.
  notFound,

  /// No ID equals the text and the list shows more than one player.
  manyMatches,

  /// The session is at capacity and the target is not checked in.
  sessionFull,

  /// The target is Disabled.
  disabled,

  /// More than one listed player has that exact ID.
  duplicateId,
}

/// What one scan (Enter in the scan field) did. The scan result box shows
/// it until the next scan (R3-Q3).
class ScanResult {
  const ScanResult._(
    this.kind, {
    this.player,
    this.text = '',
    this.count = 0,
    this.round = 0,
    this.fill,
    this.checkedIn = 0,
    this.capacity = 0,
  });

  const ScanResult.ready() : this._(ScanKind.ready);

  const ScanResult.checkedIn(Player player, {required int round})
    : this._(ScanKind.checkedIn, player: player, round: round);

  /// [fill] is the place the fill rule filled, if any (PLY-18).
  const ScanResult.checkedOut(Player player, {SlotFill? fill})
    : this._(ScanKind.checkedOut, player: player, fill: fill);

  const ScanResult.scannedTwice(Player player)
    : this._(ScanKind.scannedTwice, player: player);

  const ScanResult.notFound(String text)
    : this._(ScanKind.notFound, text: text);

  const ScanResult.manyMatches(String text, int count)
    : this._(ScanKind.manyMatches, text: text, count: count);

  const ScanResult.sessionFull(
    Player player, {
    required int checkedIn,
    required int capacity,
  }) : this._(
         ScanKind.sessionFull,
         player: player,
         checkedIn: checkedIn,
         capacity: capacity,
       );

  const ScanResult.disabled(Player player)
    : this._(ScanKind.disabled, player: player);

  const ScanResult.duplicateId(String id, int count)
    : this._(ScanKind.duplicateId, text: id, count: count);

  final ScanKind kind;

  /// The target of the scan, when there is one.
  final Player? player;

  /// The scanned text (NOT FOUND, MANY MATCHES) or the ID (DUPLICATE ID).
  final String text;

  /// How many players match (MANY MATCHES) or share the ID (DUPLICATE ID).
  final int count;

  /// The round a checked-in player waits for (PLY-17).
  final int round;

  /// The place the fill rule gave to another player (PLY-18).
  final SlotFill? fill;

  /// The counts for SESSION FULL.
  final int checkedIn;
  final int capacity;

  /// The fill to name in the CHECKED OUT text: the earliest round first,
  /// then the lowest court.
  static SlotFill? firstFill(List<SlotFill> fills) {
    if (fills.isEmpty) return null;
    return fills.reduce(
      (a, b) =>
          b.round < a.round ||
              (b.round == a.round && b.courtIndex < a.courtIndex)
          ? b
          : a,
    );
  }
}
