import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/repository/player_repository.dart';
import 'package:good_bad_board/state/persistent_setting.dart';

/// The Settings tab — notification toggles, membership summary, invite link,
/// and level calibration note.
///
/// Implements SET-01 through SET-04 from the UAT spec.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _sessionReminders = false;
  bool _courtAlerts = false;
  bool _generalAnnouncements = false;

  @override
  void initState() {
    super.initState();
    final ps = PersistentSetting.instance;
    _sessionReminders = ps.getSessionReminders();
    _courtAlerts = ps.getCourtAlerts();
    _generalAnnouncements = ps.getGeneralAnnouncements();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    // Read player counts from the repository for membership summary.
    // Guard against uninitialized repository in test environments.
    int totalMembers;
    try {
      totalMembers = PlayerRepository.instance.listedPlayers().length;
    } catch (_) {
      totalMembers = 0;
    }

    return SingleChildScrollView(
      padding: AppSpacing.desktopPadding,
      child: isWide
          ? _buildWideLayout(totalMembers)
          : _buildNarrowLayout(totalMembers),
    );
  }

  Widget _buildWideLayout(int totalMembers) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildNotificationsCard()),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _buildMembershipCard(totalMembers)),
      ],
    );
  }

  Widget _buildNarrowLayout(int totalMembers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotificationsCard(),
        const SizedBox(height: AppSpacing.lg),
        _buildMembershipCard(totalMembers),
      ],
    );
  }

  // ── Notifications Card (SET-01) ────────────────────────

  Widget _buildNotificationsCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Notifications', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.lg),

          _NotificationToggleRow(
            label: 'Session reminders',
            value: _sessionReminders,
            onChanged: (v) {
              setState(() => _sessionReminders = v);
              PersistentSetting.instance.setSessionReminders(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          _NotificationToggleRow(
            label: 'Court assignment alerts',
            value: _courtAlerts,
            onChanged: (v) {
              setState(() => _courtAlerts = v);
              PersistentSetting.instance.setCourtAlerts(v);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          _NotificationToggleRow(
            label: 'General announcements',
            value: _generalAnnouncements,
            onChanged: (v) {
              setState(() => _generalAnnouncements = v);
              PersistentSetting.instance.setGeneralAnnouncements(v);
            },
          ),
        ],
      ),
    );
  }

  // ── Membership Card (SET-02, SET-03, SET-04) ───────────

  Widget _buildMembershipCard(int totalMembers) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Membership & self-registration',
            style: AppTypography.cardTitle,
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Membership counts (SET-02) ──────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total members', style: AppTypography.statLabel),
                    const SizedBox(height: AppSpacing.xs),
                    Text('$totalMembers', style: AppTypography.statValue),
                  ],
                ),
              ),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Fees outstanding', style: AppTypography.statLabel),
                    SizedBox(height: AppSpacing.xs),
                    Text('0', style: AppTypography.statValue),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Invite link (SET-03) ────────────────────
          const Text('Invite link', style: AppTypography.statLabel),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.inputBorder),
              borderRadius: AppRadii.mdRadius,
            ),
            child: Text(
              PersistentSetting.instance.getInviteLink(),
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () => context.push('/register'),
            child: Text(
              'Preview signup page →',
              style: AppTypography.body.copyWith(
                color: AppColors.accentPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // ── Level calibration note (SET-04) ─────────
          Text(
            'New players self-estimate their level at signup, and organizers '
            'may override any estimate from the Players tab.',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

/// A notification toggle row showing both "On" and "Off" labels.
///
/// Both labels are always visible; the active state is visually highlighted
/// while the inactive state is dimmed.
class _NotificationToggleRow extends StatelessWidget {
  const _NotificationToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const _activeStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.white,
  );

  static const _inactiveStyle = TextStyle(
    fontFamily: AppTypography.bodyFont,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.toggleOffText,
  );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: AppTypography.body,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => onChanged(true),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: value ? AppColors.success : AppColors.toggleOff,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    bottomLeft: Radius.circular(6),
                  ),
                ),
                child: Text('On', style: value ? _activeStyle : _inactiveStyle),
              ),
            ),
            GestureDetector(
              onTap: () => onChanged(false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: !value ? AppColors.success : AppColors.toggleOff,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(6),
                    bottomRight: Radius.circular(6),
                  ),
                ),
                child: Text(
                  'Off',
                  style: !value ? _activeStyle : _inactiveStyle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
