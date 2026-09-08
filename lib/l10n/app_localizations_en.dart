// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get about => 'About';

  @override
  String get add => 'Add';

  @override
  String get add_player => 'Add Player';

  @override
  String get anonymised_player => 'Deleted player';

  @override
  String get app_name => 'Badminton Game Generator';

  @override
  String get are_you_sure_you_want_to_delete_this_player =>
      'Are you sure you want to delete this player?';

  @override
  String get are_you_sure_you_want_to_exit => 'Are you sure you want to exit?';

  @override
  String get auto_game => 'Auto Game';

  @override
  String auto_game_status(String status) {
    return 'Auto game generation is $status';
  }

  @override
  String get break_ => 'Break';

  @override
  String get cancel => 'Cancel';

  @override
  String get coming_soon => 'Coming Soon';

  @override
  String get court_background => 'Court Background';

  @override
  String court_n(int n) {
    return 'Court $n';
  }

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get elo => 'Elo';

  @override
  String get email => 'Email';

  @override
  String get first_name => 'First Name';

  @override
  String get game_based => 'Game Based';

  @override
  String get game_duration => 'Game Duration';

  @override
  String get game_history => 'Game History';

  @override
  String get game_is_currently_running => 'Game is currently running...';

  @override
  String game_number(int n) {
    return 'Game $n';
  }

  @override
  String get game_type => 'Game Type';

  @override
  String get games_history => 'Games History';

  @override
  String get generate_game => 'Generate Game';

  @override
  String get generate_some_game_to_start => 'Generate some games to start';

  @override
  String get history => 'History';

  @override
  String get id => 'ID';

  @override
  String get language => 'Language';

  @override
  String get language_name => 'English';

  @override
  String get last_name => 'Last Name';

  @override
  String get make_game => 'Make Game';

  @override
  String get most_games_played => 'Most Games Played';

  @override
  String get most_sessions_attended => 'Most Sessions Attended';

  @override
  String n_court(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Courts',
      one: '1 Court',
      zero: 'No Court',
    );
    return '$_temp0';
  }

  @override
  String get off => 'Off';

  @override
  String get ok => 'OK';

  @override
  String get on => 'On';

  @override
  String player_deleted(String id) {
    return 'Player $id deleted';
  }

  @override
  String get player_register => 'Player Register';

  @override
  String get player_statistic => 'Player Statistics';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get regenerate_game => 'Regenerate Game';

  @override
  String get reset => 'Reset';

  @override
  String get save => 'Save';

  @override
  String get settings => 'Settings';

  @override
  String get sign_in_id => 'Sign In ID';

  @override
  String skill_gap_n(num gap) {
    return 'Skill Gap: $gap';
  }

  @override
  String get the_beginning => 'The Beginning';

  @override
  String get time_based => 'Time Based';

  @override
  String get time_remaining => 'Time Remaining';

  @override
  String get to_current_session => 'To current session';

  @override
  String get today => 'Today';

  @override
  String get update => 'Update';
}
