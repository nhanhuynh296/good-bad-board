import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/registration/confirmation_screen.dart';
import 'package:good_bad_board/features/registration/level_selector.dart';
import 'package:good_bad_board/l10n/skill_tier_l10n.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/elo.dart';
import 'package:good_bad_board/model/pending_registration.dart';
import 'package:good_bad_board/repository/pending_registration_repository.dart';

/// Standalone public self-registration page (REG-01…07).
///
/// Reached at the top-level `/register` route, outside the admin
/// [ResponsiveShell] — this is filled in by a prospective player, not an
/// organizer, and stays a single centered column at every width (REG-07).
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  SkillTier _selectedTier = SkillTier.intermediate;
  bool _submitted = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      !_submitting &&
      _nameController.text.trim().isNotEmpty &&
      _contactController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    final registration = PendingRegistration.create(
      name: _nameController.text.trim(),
      contact: _contactController.text.trim(),
      tier: _selectedTier,
    );
    await PendingRegistrationRepository.instance.add(registration);
    if (!mounted) return;
    setState(() {
      _submitting = false;
      _submitted = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.xl2,
              ),
              child: _submitted
                  ? ConfirmationScreen(
                      firstName: _nameController.text.trim().split(' ').first,
                      selectedTierLabel: _selectedTier.localizedLabel(
                        AppLocalizations.of(context)!,
                      ),
                    )
                  : _buildForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.registration_intro,
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(l10n.registration_name, style: AppTypography.statLabel),
          const SizedBox(height: AppSpacing.xs),
          AppSearchInput(
            controller: _nameController,
            placeholder: l10n.registration_name_hint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.registration_contact, style: AppTypography.statLabel),
          const SizedBox(height: AppSpacing.xs),
          AppSearchInput(
            controller: _contactController,
            placeholder: l10n.registration_contact_hint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.registration_level_question,
            style: AppTypography.statLabel,
          ),
          const SizedBox(height: AppSpacing.sm),
          LevelSelector(
            selectedTier: _selectedTier,
            onTierSelected: (tier) => setState(() => _selectedTier = tier),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton.primary(
            label: l10n.registration_submit,
            onPressed: _canSubmit ? _submit : null,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.registration_review_note,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: AppTypography.family,
              fontSize: AppTypography.sizeCaption,
              fontWeight: AppTypography.regular,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
