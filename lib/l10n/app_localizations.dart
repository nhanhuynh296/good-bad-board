import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('zh'),
    Locale('zh', 'HK'),
  ];

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @add_player.
  ///
  /// In en, this message translates to:
  /// **'Add Player'**
  String get add_player;

  /// Placeholder shown in place of the name of a Player who has been anonymised (deleted)
  ///
  /// In en, this message translates to:
  /// **'Deleted player'**
  String get anonymised_player;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Badminton Game Generator'**
  String get app_name;

  /// Confirmation message when deleting a player
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this player?'**
  String get are_you_sure_you_want_to_delete_this_player;

  /// No description provided for @are_you_sure_you_want_to_exit.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to exit?'**
  String get are_you_sure_you_want_to_exit;

  /// Automatically generate games after a session ends
  ///
  /// In en, this message translates to:
  /// **'Auto Game'**
  String get auto_game;

  /// Status of the auto game feature (On/Off)
  ///
  /// In en, this message translates to:
  /// **'Auto game generation is {status}'**
  String auto_game_status(String status);

  /// Temporarily exclude a player from gameplay
  ///
  /// In en, this message translates to:
  /// **'Break'**
  String get break_;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get coming_soon;

  /// No description provided for @court_background.
  ///
  /// In en, this message translates to:
  /// **'Court Background'**
  String get court_background;

  /// Label for a badminton court (e.g., Court 1)
  ///
  /// In en, this message translates to:
  /// **'Court {n}'**
  String court_n(int n);

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Player skill rating system
  ///
  /// In en, this message translates to:
  /// **'Elo'**
  String get elo;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// Game format (e.g., 21-point matches)
  ///
  /// In en, this message translates to:
  /// **'Game Based'**
  String get game_based;

  /// No description provided for @game_duration.
  ///
  /// In en, this message translates to:
  /// **'Game Duration'**
  String get game_duration;

  /// No description provided for @game_history.
  ///
  /// In en, this message translates to:
  /// **'Game History'**
  String get game_history;

  /// No description provided for @game_is_currently_running.
  ///
  /// In en, this message translates to:
  /// **'Game is currently running...'**
  String get game_is_currently_running;

  /// Sequential game number (e.g., Game 3)
  ///
  /// In en, this message translates to:
  /// **'Game {n}'**
  String game_number(int n);

  /// Singles, doubles, or mixed doubles
  ///
  /// In en, this message translates to:
  /// **'Game Type'**
  String get game_type;

  /// No description provided for @games_history.
  ///
  /// In en, this message translates to:
  /// **'Games History'**
  String get games_history;

  /// No description provided for @generate_game.
  ///
  /// In en, this message translates to:
  /// **'Generate Game'**
  String get generate_game;

  /// No description provided for @generate_some_game_to_start.
  ///
  /// In en, this message translates to:
  /// **'Generate some games to start'**
  String get generate_some_game_to_start;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Unique player identifier
  ///
  /// In en, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Language name in its native form
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get language_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// Create a new game session
  ///
  /// In en, this message translates to:
  /// **'Make Game'**
  String get make_game;

  /// No description provided for @most_games_played.
  ///
  /// In en, this message translates to:
  /// **'Most Games Played'**
  String get most_games_played;

  /// No description provided for @most_sessions_attended.
  ///
  /// In en, this message translates to:
  /// **'Most Sessions Attended'**
  String get most_sessions_attended;

  /// Number of courts in use
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No Court} =1{1 Court} other{{count} Courts}}'**
  String n_court(num count);

  /// Feature disabled
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Feature enabled
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get on;

  /// Notification after player deletion
  ///
  /// In en, this message translates to:
  /// **'Player {id} deleted'**
  String player_deleted(String id);

  /// No description provided for @player_register.
  ///
  /// In en, this message translates to:
  /// **'Player Register'**
  String get player_register;

  /// View player statistics
  ///
  /// In en, this message translates to:
  /// **'Player Statistics'**
  String get player_statistic;

  /// Recreate a game with new parameters
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// No description provided for @regenerate_game.
  ///
  /// In en, this message translates to:
  /// **'Regenerate Game'**
  String get regenerate_game;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @sign_in_id.
  ///
  /// In en, this message translates to:
  /// **'Sign In ID'**
  String get sign_in_id;

  /// Difference in Elo ratings between players
  ///
  /// In en, this message translates to:
  /// **'Skill Gap: {gap}'**
  String skill_gap_n(num gap);

  /// Start of a session or timeline
  ///
  /// In en, this message translates to:
  /// **'The Beginning'**
  String get the_beginning;

  /// Game format with fixed duration (e.g., 30 minutes)
  ///
  /// In en, this message translates to:
  /// **'Time Based'**
  String get time_based;

  /// Countdown for ongoing game/session
  ///
  /// In en, this message translates to:
  /// **'Time Remaining'**
  String get time_remaining;

  /// No description provided for @to_current_session.
  ///
  /// In en, this message translates to:
  /// **'To current session'**
  String get to_current_session;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.countryCode) {
          case 'HK':
            return AppLocalizationsZhHk();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
