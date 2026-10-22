import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';

AppLocalizations l10n(String tag) => lookupAppLocalizations(Locale(tag));

void main() {
  group('ANA-06/09/13: analytics count strings', () {
    test('should_use_singular_verb_for_one_flagged_court_in_en', () {
      expect(
        l10n('en').analytics_courts_absorb_overflow(1, '3'),
        'Court 3 regularly absorbs overflow with wider gaps.',
      );
    });

    test('should_use_plural_verb_for_several_flagged_courts_in_en', () {
      expect(
        l10n('en').analytics_courts_absorb_overflow(2, '2, 3'),
        'Courts 2, 3 regularly absorb overflow with wider gaps.',
      );
    });

    test('should_use_singular_player_for_one_stagnant_player_in_en', () {
      expect(l10n('en').analytics_stagnation(1), '1 player flat 6+ sessions');
    });

    test('should_use_plural_players_for_several_stagnant_in_en', () {
      expect(l10n('en').analytics_stagnation(3), '3 players flat 6+ sessions');
    });

    test('should_use_singular_session_for_one_session_in_en', () {
      expect(
        l10n('en').analytics_joined_sessions('10/3', 1),
        'Joined 10/3 · 1 session',
      );
    });

    test('should_use_plural_sessions_for_several_sessions_in_en', () {
      expect(
        l10n('en').analytics_joined_sessions('10/3', 4),
        'Joined 10/3 · 4 sessions',
      );
    });

    test('should_use_singular_player_for_one_stagnant_player_in_fr', () {
      expect(
        l10n('fr').analytics_stagnation(1),
        '1 joueur sans progression depuis 6+ sessions',
      );
    });

    test('should_use_plural_players_for_several_stagnant_in_fr', () {
      expect(
        l10n('fr').analytics_stagnation(3),
        '3 joueurs sans progression depuis 6+ sessions',
      );
    });

    test('should_use_singular_session_for_one_session_in_fr', () {
      expect(
        l10n('fr').analytics_joined_sessions('10/3', 1),
        'Inscrit le 10/3 · 1 session',
      );
    });

    test('should_use_plural_sessions_for_several_sessions_in_fr', () {
      expect(
        l10n('fr').analytics_joined_sessions('10/3', 4),
        'Inscrit le 10/3 · 4 sessions',
      );
    });

    for (final tag in ['zh', 'zh_HK']) {
      test('should_render_counts_with_other_form_only_in_$tag', () {
        final t = tag == 'zh'
            ? l10n('zh')
            : lookupAppLocalizations(const Locale('zh', 'HK'));
        expect(t.analytics_stagnation(1), contains('1'));
        expect(t.analytics_joined_sessions('10/3', 1), contains('1'));
      });
    }
  });
}
