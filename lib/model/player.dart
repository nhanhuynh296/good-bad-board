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

/// A player's club-membership standing.
///
/// Cycles Member → Casual → Disabled → Member via [next]. Disabled players
/// are excluded from check-in and the session pool (see [GameData]).
enum MembershipStatus {
  member,
  casual,
  disabled;

  MembershipStatus get next => switch (this) {
    MembershipStatus.member => MembershipStatus.casual,
    MembershipStatus.casual => MembershipStatus.disabled,
    MembershipStatus.disabled => MembershipStatus.member,
  };

  String toDisplayName() => switch (this) {
    MembershipStatus.member => 'Member',
    MembershipStatus.casual => 'Casual',
    MembershipStatus.disabled => 'Disabled',
  };
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
    @Default(MembershipStatus.member) MembershipStatus membership,
    DateTime? deletedDate,
  }) = _Player;

  factory Player.create({
    required String firstName,
    required String lastName,
    required Elo elo,
    String? signInId,
    MembershipStatus membership = MembershipStatus.member,
  }) => Player(
    firstName: firstName,
    lastName: lastName,
    elo: elo,
    signInId: signInId,
    id: const Uuid().v4(),
    createdDate: DateTime.now(),
    membership: membership,
  );

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);

  static String jsonReferencedPlayer(Player player) => player.id;

  String toDisplayString() =>
      '$firstName $lastName (${elo.name.toUpperCase()})';

  String name() => '$firstName $lastName';

  /// Whether this is an anonymised Player — see ADR-0001. The id, the Elo
  /// and the created date stay; the name and sign-in id are erased.
  bool get isAnonymised => deletedDate != null;
}
