import 'package:good_bad_board/model/game.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:json_annotation/json_annotation.dart';

part 'players.g.dart';

@JsonSerializable()
class SessionDto {
  final Iterable<Player> players;
  @JsonKey(toJson: _sessionSerializer)
  final Iterable<Iterable<Game>> games;

  SessionDto({required this.players, required this.games});

  factory SessionDto.fromJson(Map<String, dynamic> json) =>
      _$SessionDtoFromJson(json);

  Map<String, dynamic> toJson() => _$SessionDtoToJson(this);

  // Json Serialization

  static List<List<String>> _gamesSerializer(Iterable<Game> games) =>
      games.map(Game.gameSerializer).toList(growable: false);

  static List<List<List<String>>> _sessionSerializer(
    Iterable<Iterable<Game>> session,
  ) => session.map(_gamesSerializer).toList(growable: false);
}
