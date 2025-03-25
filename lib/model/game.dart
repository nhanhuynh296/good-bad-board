import 'package:collection/collection.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:json_annotation/json_annotation.dart';

part 'game.g.dart';

@JsonSerializable(explicitToJson: true)
class Game {
  static const int playerPerCourt = 4;

  final List<Player> players;

  Game(this.players) : assert(players.length == playerPerCourt);

  int eloGap() {
    final sortedPlayers = players.sortedBy((player) => player.elo.index);
    return (sortedPlayers.last.elo.index - sortedPlayers.first.elo.index).abs();
  }

  // Json Serialization

  factory Game.fromJson(Map<String, dynamic> json) => _$GameFromJson(json);

  Map<String, dynamic> toJson() => _$GameToJson(this);

  static List<String> gameSerializer(Game game) =>
      game.players.map(Player.jsonReferencedPlayer).toList(growable: false);
}
