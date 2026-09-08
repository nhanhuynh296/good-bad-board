/// A saved session configuration template.
///
/// Captures round mode, duration, capacity, and court count so organizers
/// can save and restore session configurations.
class SessionTemplate {
  final String name;

  /// 0 = gameBased, 1 = timeBased
  final int modeIndex;

  /// Whole-minute part of the rotation duration.
  final int durationMinutes;

  /// Second part of the rotation duration (0–59).
  ///
  /// Templates saved before rounds could carry seconds have no value stored,
  /// so this defaults to 0.
  final int durationSeconds;

  /// Maximum number of checked-in players.
  final int capacity;

  /// Number of courts (1–8).
  final int courts;

  const SessionTemplate({
    required this.name,
    required this.modeIndex,
    required this.durationMinutes,
    this.durationSeconds = 0,
    required this.capacity,
    required this.courts,
  });

  /// The rotation duration this template restores.
  Duration get duration =>
      Duration(minutes: durationMinutes, seconds: durationSeconds);

  /// Serializes this template to a JSON-encodable map.
  Map<String, dynamic> toJson() => {
    'name': name,
    'modeIndex': modeIndex,
    'durationMinutes': durationMinutes,
    'durationSeconds': durationSeconds,
    'capacity': capacity,
    'courts': courts,
  };

  /// Deserializes a template from a JSON map.
  factory SessionTemplate.fromJson(Map<String, dynamic> json) {
    return SessionTemplate(
      name: json['name'] as String,
      modeIndex: json['modeIndex'] as int,
      durationMinutes: json['durationMinutes'] as int,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      capacity: json['capacity'] as int,
      courts: json['courts'] as int,
    );
  }
}
