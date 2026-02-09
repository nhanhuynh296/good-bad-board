import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:good_bad_board/repository/database_helper.dart';
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
    DateTime? createdDate,
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
    createdDate: DateTime.now(),
  );

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  Map<String, dynamic> toJson() => _$PlayerToJson(this as _Player);

  factory Player.fromSqliteRow(Map<String, Object?> row) {
    final createdDate = row['createdDate'] as int?;
    return Player(
      firstName: row['firstName'] as String,
      lastName: row['lastName'] as String,
      elo: Elo.values[row['elo'] as int],
      id: row['id'] as String,
      signInId: row['signInId'] as String?,
      createdDate: createdDate == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(createdDate),
    );
  }

  static String jsonReferencedPlayer(Player player) => player.id;

  Map<String, Object?> toSqliteRow() {
    final json = _$PlayerToJson(this as _Player);
    json['createdDate'] = DatabaseHelper.sqlLiteDateTimeSerializer(createdDate);
    return json;
  }

  String toDisplayString() =>
      '$firstName $lastName (${elo.name.toUpperCase()})';

  String name() => '$firstName $lastName';
}
