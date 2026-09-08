// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get about => 'À propos';

  @override
  String get add => 'Ajouter';

  @override
  String get add_player => 'Ajouter un joueur';

  @override
  String get anonymised_player => 'Joueur supprimé';

  @override
  String get app_name => 'Générateur de matchs de badminton';

  @override
  String get are_you_sure_you_want_to_delete_this_player =>
      'Êtes-vous sûr de vouloir supprimer ce joueur ?';

  @override
  String get are_you_sure_you_want_to_exit =>
      'Êtes-vous sûr de vouloir quitter ?';

  @override
  String get auto_game => 'Partie automatique';

  @override
  String auto_game_status(String status) {
    return 'Génération automatique de parties : $status';
  }

  @override
  String get break_ => 'Pause';

  @override
  String get cancel => 'Annuler';

  @override
  String get coming_soon => 'Bientôt disponible';

  @override
  String get court_background => 'Arrière-plan du terrain';

  @override
  String court_n(int n) {
    return 'Terrain $n';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get done => 'Terminé';

  @override
  String get elo => 'Elo';

  @override
  String get email => 'E-mail';

  @override
  String get first_name => 'Prénom';

  @override
  String get game_based => 'Partie en points';

  @override
  String get game_duration => 'Durée de la partie';

  @override
  String get game_history => 'Historique des parties';

  @override
  String get game_is_currently_running => 'Partie en cours...';

  @override
  String game_number(int n) {
    return 'Partie $n';
  }

  @override
  String get game_type => 'Type de partie';

  @override
  String get games_history => 'Historique des parties';

  @override
  String get generate_game => 'Générer une partie';

  @override
  String get generate_some_game_to_start =>
      'Générez des parties pour commencer';

  @override
  String get history => 'History';

  @override
  String get id => 'ID';

  @override
  String get language => 'Langue';

  @override
  String get language_name => 'Français';

  @override
  String get last_name => 'Nom de famille';

  @override
  String get make_game => 'Créer une partie';

  @override
  String get most_games_played => 'Plus de parties jouées';

  @override
  String get most_sessions_attended => 'Plus de sessions suivies';

  @override
  String n_court(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terrains',
      one: '1 terrain',
      zero: 'Aucun terrain',
    );
    return '$_temp0';
  }

  @override
  String get off => 'Désactivé';

  @override
  String get ok => 'OK';

  @override
  String get on => 'Activé';

  @override
  String player_deleted(String id) {
    return 'Joueur $id supprimé';
  }

  @override
  String get player_register => 'Enregistrement des joueurs';

  @override
  String get player_statistic => 'Statistiques des joueurs';

  @override
  String get regenerate => 'Regénérer';

  @override
  String get regenerate_game => 'Regénérer la partie';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get save => 'Enregistrer';

  @override
  String get settings => 'Paramètres';

  @override
  String get sign_in_id => 'Identifiant de connexion';

  @override
  String skill_gap_n(num gap) {
    return 'Écart de niveau : $gap';
  }

  @override
  String get the_beginning => 'Le commencement';

  @override
  String get time_based => 'Partie chronométrée';

  @override
  String get time_remaining => 'Temps restant';

  @override
  String get to_current_session => 'To current session';

  @override
  String get today => 'Aujourd’hui';

  @override
  String get update => 'Mettre à jour';
}
