import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/player.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

import 'support/prefs_sandbox.dart';
import 'support/repository_sandbox.dart';

// R45-38: checkInPlayer says why it refused a check-in.

void main() {
  late RepositorySandbox sandbox;

  setUp(() async {
    mockPreferences({});
    await PersistentSetting.instance.initialize();
    sandbox = await RepositorySandbox.setUp('game_data_check_in_result_test');
  });

  tearDown(() => sandbox.tearDown());

  test('should_return_checked_in_for_a_member', () async {
    final player = (await createTestPlayers(1)).single;

    expect(GameData().checkInPlayer(player), CheckInResult.checkedIn);
  });

  test('should_return_checked_in_for_a_player_already_checked_in', () async {
    final player = (await createTestPlayers(1)).single;
    final gameData = GameData()..checkInPlayer(player);

    expect(gameData.checkInPlayer(player), CheckInResult.checkedIn);
  });

  test('should_return_disabled_for_a_disabled_player', () async {
    final player = (await createTestPlayers(
      1,
    )).single.copyWith(membership: MembershipStatus.disabled);

    expect(GameData().checkInPlayer(player), CheckInResult.disabled);
  });

  test('should_return_session_full_at_capacity', () async {
    final players = await createTestPlayers(GameData.minSessionCapacity + 1);
    final gameData = GameData()
      ..setSessionCapacity(GameData.minSessionCapacity);
    players.take(GameData.minSessionCapacity).forEach(gameData.checkInPlayer);

    expect(gameData.checkInPlayer(players.last), CheckInResult.sessionFull);
  });
}
