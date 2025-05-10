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
  final String firstName;
  final String lastName;
  final Elo elo;
  final String id;
  final String? signInId;

  Player({
    required this.firstName,
    required this.lastName,
    required this.elo,
    this.signInId,
  }) : id = const Uuid().v4();

  String toDisplayString() =>
      '$firstName $lastName (${elo.name.toUpperCase()})';

  String name() => '$firstName $lastName';

  Player copyWith({
    String? firstName,
    String? lastName,
    Elo? elo,
    String? signInId,
  }) {
    return Player._jsonConstructor(
      firstName ?? this.firstName,
      lastName ?? this.lastName,
      elo ?? this.elo,
      id,
      signInId ?? this.signInId,
    );
  }

  // Json Serialization
  Player._jsonConstructor(
    this.firstName,
    this.lastName,
    this.elo,
    this.id,
    this.signInId,
  );

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this);

  static String jsonReferencedPlayer(Player player) => player.id;
}
