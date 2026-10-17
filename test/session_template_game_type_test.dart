import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

// R45-04: a template stores its round mode by GameType name.

SessionTemplate _template(GameType type) => SessionTemplate(
  id: 't1',
  name: 'Tuesday',
  gameType: type,
  durationMinutes: 10,
  capacity: 16,
  courts: 4,
);

Map<String, dynamic> _legacyJson(int modeIndex) => {
  'id': 't1',
  'name': 'Tuesday',
  'modeIndex': modeIndex,
  'durationMinutes': 10,
  'capacity': 16,
  'courts': 4,
};

void main() {
  test('should_write_the_game_type_name_to_json', () {
    final json = _template(GameType.gameBased).toJson();

    expect(json['gameType'], 'gameBased');
  });

  test('should_not_write_the_mode_index_to_json', () {
    final json = _template(GameType.timeBased).toJson();

    expect(json.containsKey('modeIndex'), isFalse);
  });

  test('should_read_back_the_game_type_it_wrote', () {
    final json = _template(GameType.gameBased).toJson();

    expect(SessionTemplate.fromJson(json).gameType, GameType.gameBased);
  });

  test('should_read_a_legacy_mode_index_of_1_as_time_based', () {
    final template = SessionTemplate.fromJson(_legacyJson(1));

    expect(template.gameType, GameType.timeBased);
  });

  test('should_read_a_legacy_mode_index_of_0_as_game_based', () {
    final template = SessionTemplate.fromJson(_legacyJson(0));

    expect(template.gameType, GameType.gameBased);
  });

  test('should_read_an_unknown_game_type_name_as_time_based', () {
    final json = _template(GameType.gameBased).toJson()
      ..['gameType'] = 'futureMode';

    expect(SessionTemplate.fromJson(json).gameType, GameType.timeBased);
  });
}
