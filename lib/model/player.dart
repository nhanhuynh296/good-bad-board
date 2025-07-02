import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'player.freezed.dart';
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

@freezed
abstract class Player with _$Player {
  const Player._();

  factory Player({
    required String firstName,
    required String lastName,
    required Elo elo,
    required String id,
    String? signInId,
  }) = _Player;

  factory Player.create({
    required String firstName,
    required String lastName,
    required Elo elo,
    String? signInId,
  }) => Player(
    firstName: firstName,
    lastName: lastName,
    elo: elo,
    signInId: signInId,
    id: const Uuid().v4(),
  );

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  static String jsonReferencedPlayer(Player player) => player.id;

  String toDisplayString() =>
      '$firstName $lastName (${elo.name.toUpperCase()})';

  String name() => '$firstName $lastName';
}
