import 'dart:math';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:uuid/uuid.dart';

part 'game.freezed.dart';
part 'game.g.dart';

@Freezed(
  equal: false,
  copyWith: false,
  addImplicitFinal: true,
  makeCollectionsUnmodifiable: false,
)
abstract class Game with _$Game {
  static const int playerPerCourt = 4;
  static const int singlePlayerPerCourt = 2;
  static const acceptablePlayerNumber = [playerPerCourt, singlePlayerPerCourt];

  const Game._();

  factory Game({
    required List<String> playerIds,
    required String id,
    required DateTime createdDate,
  }) = _Game;

  factory Game.create(Iterable<Player> players) => Game(
    playerIds: players.map((player) => player.id).toList(growable: true),
    id: const Uuid().v4(),
    createdDate: DateTime.now(),
  );

  /// [playerIds] resolved to [Player]s via [PlayerRepository], anonymised
  /// players included (ADR-0001). An id that resolves to nothing is dropped
  /// from this snapshot — it still stays in [playerIds] and on disk.
  ///
  /// Reaches the singleton directly rather than taking a resolver parameter,
  /// unlike `analytics_engine.dart`'s `resolvePlayer` callbacks — that file
  /// stays free of `PlayerRepository` on purpose, so its test suite can stay
  /// pure Dart with no repository/file-IO setup. `Game` has no such
  /// constraint: every caller (`GameData`, `GameRepository`, the widget
  /// layer) already runs with `PlayerRepository.instance` initialized.
  List<Player> get players => playerIds
      .map(PlayerRepository.instance.byId)
      .nonNulls
      .toList(growable: true);

  int eloGap() {
    if (players.length < 2) return 0;
    final sortedPlayers = players.sortedBy((player) => player.elo.index);
    return (sortedPlayers.last.elo.index - sortedPlayers.first.elo.index).abs();
  }

  /// Gap between the highest and lowest [SkillTier] on the court (0 to 3).
  ///
  /// For display only (UAT glossary: "level gap"). Session logs store
  /// [eloGap], which analytics divides by 2, so do not store this value.
  int tierGap() {
    if (players.length < 2) return 0;
    final tiers = players.map((player) => player.elo.skillTier.index);
    return tiers.reduce(max) - tiers.reduce(min);
  }

  Iterable<int> elos() {
    return players.map((player) => player.elo.index);
  }

  /// Whether this court holds a full or a doubles-eligible number of slots.
  /// Counts slots ([playerIds]), not resolved [players] — an unresolvable id
  /// still occupies a slot.
  bool isPlayable() => acceptablePlayerNumber.contains(playerIds.length);

  // Json Serialization
  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}
