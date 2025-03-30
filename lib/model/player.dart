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
  s1;

  String toDisplayName() => name.toUpperCase();
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
  final String? signInId;

  Player({required this.name, required this.elo, this.signInId})
    : id = const Uuid().v4();

  String toDisplayString() => '$name (${elo.name.toUpperCase()})';

  // Json Serialization
  Player._jsonConstructor(this.name, this.elo, this.id, this.signInId);

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  static String jsonReferencedPlayer(Player player) => player.id;
}
