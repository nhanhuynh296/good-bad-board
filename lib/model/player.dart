import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

part 'player.g.dart';

enum Elo {
  c2, // Newbie
  c1, // Trinity
  b2, // Ryan
  b1, // Wei
  a2, // Nathan
  a1, // Justin
  s2, // Josh
  s1,
}

@JsonSerializable(
  includeIfNull: true,
  constructor: '_jsonConstructor',
  createPerFieldToJson: true,
)
class Player {
  final String name;
  final Elo elo;
  final String id;

  Player({required this.name, required this.elo}) : id = const Uuid().v4();

  // Json Serialization
  Player._jsonConstructor(this.name, this.elo, this.id);

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  static String jsonReferencedPlayer(Player player) => player.id;
}
