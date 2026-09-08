import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Setting {
  background,
  gameType,
  gameDuration,
  language,
  autoMakegame,
  sessionReminders,
  courtAlerts,
  generalAnnouncements,
  inviteLink,
  templates,
}

enum GameType {
  timeBased,
  gameBased;

  String toDisplayString(BuildContext context) => switch (this) {
    GameType.timeBased => AppLocalizations.of(context)!.time_based,
    GameType.gameBased => AppLocalizations.of(context)!.game_based,
  };
}

class PersistentSetting extends ChangeNotifier {
  PersistentSetting._init();

  static final PersistentSetting instance = PersistentSetting._init();

  SharedPreferences? _prefs;

  SharedPreferences get sharedPreference {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'PersistentSetting not initialized. Call initialize() first.',
      );
    }
    return prefs;
  }

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> setCourtBackground(String image) async {
    await sharedPreference.setString(Setting.background.name, image);
    notifyListeners();
  }

  String getBackground() =>
      sharedPreference.getString(Setting.background.name) ??
      'asset/image/badminton.webp';

  Future<void> setGameType(GameType type) async {
    await sharedPreference.setString(Setting.gameType.name, type.name);
    notifyListeners();
  }

  Future<void> setGameDuration(Duration duration) async {
    await sharedPreference.setInt(
      Setting.gameDuration.name,
      duration.inSeconds,
    );
    notifyListeners();
  }

  Duration getGameDuration() {
    return Duration(
      seconds:
          sharedPreference.getInt(Setting.gameDuration.name) ??
          10 * Duration.secondsPerMinute,
    );
  }

  GameType getGameType() => GameType.values.firstWhere(
    (element) =>
        element.name == sharedPreference.getString(Setting.gameType.name),
    orElse: () => GameType.timeBased,
  );

  Future<void> setLanguage(Locale locale) async {
    await sharedPreference.setStringList(Setting.language.name, [
      locale.languageCode,
      ?locale.countryCode,
    ]);
    notifyListeners();
  }

  Locale getLanguage() {
    final localeString = sharedPreference.getStringList(Setting.language.name);
    if (localeString == null) return const Locale('en');
    final languageCode = localeString.elementAtOrNull(0) ?? 'en';
    final countryCode = localeString.elementAtOrNull(1);
    return Locale(languageCode, countryCode);
  }

  Future<void> setAutoMakeGame(bool value) async {
    await sharedPreference.setBool(Setting.autoMakegame.name, value);
    notifyListeners();
  }

  bool getAutoMakeGame() {
    return sharedPreference.getBool(Setting.autoMakegame.name) ?? false;
  }

  // ── Notification Toggles (SET-01) ──────────────────────────

  /// Returns whether session reminder notifications are enabled.
  bool getSessionReminders() =>
      sharedPreference.getBool(Setting.sessionReminders.name) ?? false;

  /// Persists the session reminder notification preference.
  Future<void> setSessionReminders(bool value) async {
    await sharedPreference.setBool(Setting.sessionReminders.name, value);
    notifyListeners();
  }

  /// Returns whether court assignment alert notifications are enabled.
  bool getCourtAlerts() =>
      sharedPreference.getBool(Setting.courtAlerts.name) ?? false;

  /// Persists the court assignment alert notification preference.
  Future<void> setCourtAlerts(bool value) async {
    await sharedPreference.setBool(Setting.courtAlerts.name, value);
    notifyListeners();
  }

  /// Returns whether general announcement notifications are enabled.
  bool getGeneralAnnouncements() =>
      sharedPreference.getBool(Setting.generalAnnouncements.name) ?? false;

  /// Persists the general announcement notification preference.
  Future<void> setGeneralAnnouncements(bool value) async {
    await sharedPreference.setBool(Setting.generalAnnouncements.name, value);
    notifyListeners();
  }

  // ── Invite Link (SET-03) ──────────────────────────────────

  /// Returns the stored invite link, or a default value if none is stored.
  String getInviteLink() =>
      sharedPreference.getString(Setting.inviteLink.name) ??
      'https://riverside-bc.example.com/join';

  /// Persists the invite link.
  Future<void> setInviteLink(String link) async {
    await sharedPreference.setString(Setting.inviteLink.name, link);
    notifyListeners();
  }

  // ── Template Persistence (SESS-05/06) ─────────────────────

  /// Persists a [template] to the stored template list.
  Future<void> persistTemplate(SessionTemplate template) async {
    final templates = loadTemplates();
    templates.add(template);
    final jsonList = templates.map((t) => t.toJson()).toList();
    await sharedPreference.setString(
      Setting.templates.name,
      jsonEncode(jsonList),
    );
    notifyListeners();
  }

  /// Loads all persisted session templates.
  List<SessionTemplate> loadTemplates() {
    final raw = sharedPreference.getString(Setting.templates.name);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SessionTemplate.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    await sharedPreference.clear();
    notifyListeners();
  }
}
