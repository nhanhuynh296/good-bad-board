import 'package:collection/collection.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game.g.dart';

@JsonSerializable(explicitToJson: true)
class Game {
  static const int playerPerCourt = 4;
  static const int singlePlayerPerCourt = 2;
  static const acceptablePlayerNumber = [playerPerCourt, singlePlayerPerCourt];

  final PlayerContainer players;

  Game(Iterable<Player> players) : players = PlayerContainer.of(players);

  int eloGap() {
    final sortedPlayers = players.sortedBy((player) => player.elo.index);
    return (sortedPlayers.last.elo.index - sortedPlayers.first.elo.index).abs();
  }

  Iterable<int> elos() {
    return players.map((player) => player.elo.index);
  }

  bool isPlayable() => acceptablePlayerNumber.contains(players.length);

  // Json Serialization

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

  Map<String, dynamic> toJson() => _$GameToJson(this);

  static List<String> gameSerializer(Game game) =>
      game.players.map(Player.jsonReferencedPlayer).toList(growable: false);
}

class PlaceholderGame extends Game {
  PlaceholderGame(super.players);

  @override
  int eloGap() {
    if (players.length < 2) return 0;
    return super.eloGap();
  }
}
