import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:uuid/uuid.dart';

/// A saved session configuration template.
///
/// Captures round mode, duration, capacity, and court count so organizers
/// can save and restore session configurations.
class SessionTemplate {
  /// Unique id — the primary key, as for every other stored row.
  final String id;

  final String name;

  /// The round mode this template restores.
  final GameType gameType;

  /// Whole-minute part of the rotation duration.
  final int durationMinutes;

  /// Second part of the rotation duration (0–59).
  ///
  /// Templates saved before rounds could carry seconds have no value stored,
  /// so this defaults to 0.
  final int durationSeconds;

  /// Maximum number of checked-in players.
  final int capacity;

  /// Number of courts: 1 or more, no upper limit (R13-Q12).
  final int courts;

  const SessionTemplate({
    required this.id,
    required this.name,
    required this.gameType,
    required this.durationMinutes,
    this.durationSeconds = 0,
    required this.capacity,
    required this.courts,
  });

  /// A new template with a fresh id.
  factory SessionTemplate.create({
    required String name,
    required GameType gameType,
    required int durationMinutes,
    int durationSeconds = 0,
    required int capacity,
    required int courts,
  }) => SessionTemplate(
    id: const Uuid().v4(),
    name: name,
    gameType: gameType,
    durationMinutes: durationMinutes,
    durationSeconds: durationSeconds,
    capacity: capacity,
    courts: courts,
  );

  /// The rotation duration this template restores.
  Duration get duration =>
      Duration(minutes: durationMinutes, seconds: durationSeconds);

  /// Serializes this template to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'gameType': gameType.name,
    'durationMinutes': durationMinutes,
    'durationSeconds': durationSeconds,
    'capacity': capacity,
    'courts': courts,
  };

  /// Deserializes a template from a JSON map.
  factory SessionTemplate.fromJson(Map<String, dynamic> json) {
    return SessionTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      gameType: _readGameType(json),
      durationMinutes: json['durationMinutes'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      capacity: json['capacity'] as int,
      courts: json['courts'] as int,
    );
  }

  /// Reads the stored [GameType] name. Templates written before R45-04 store
  /// `modeIndex` instead (0 = gameBased, 1 = timeBased). An unknown name
  /// reads as time-based, the release mode.
  static GameType _readGameType(Map<String, dynamic> json) {
    final name = json['gameType'] as String?;
    if (name != null) {
      return GameType.values.firstWhere(
        (type) => type.name == name,
        orElse: () => GameType.timeBased,
      );
    }
    return json['modeIndex'] == 0 ? GameType.gameBased : GameType.timeBased;
  }
}
