import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
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
    required PlayerContainer players,
    required String id,
    required DateTime createdDate,
  }) = _Game;

  factory Game.create(PlayerContainer players) => Game(
    players: players,
    id: const Uuid().v4(),
    createdDate: DateTime.now(),
  );

  int eloGap() {
    if (players.length < 2) return 0;
    final sortedPlayers = players.sortedBy((player) => player.elo.index);
    return (sortedPlayers.last.elo.index - sortedPlayers.first.elo.index).abs();
  }

  Iterable<int> elos() {
    return players.map((player) => player.elo.index);
  }

  bool isPlayable() => acceptablePlayerNumber.contains(players.length);

  // Json Serialization
  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);
}
