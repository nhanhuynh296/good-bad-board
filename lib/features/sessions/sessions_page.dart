import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:good_bad_board/core/duration_extension.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/features/dashboard/dashboard.dart';
import 'package:good_bad_board/l10n/app_localizations.dart';
import 'package:good_bad_board/model/session_template.dart';
import 'package:good_bad_board/state/game_data.dart';
import 'package:good_bad_board/state/persistent_setting.dart';
import 'package:good_bad_board/state/timer_data.dart';
import 'package:provider/provider.dart';

/// Largest session capacity the organizer can type in.
const int _maxSessionCapacity = 200;

/// Court-count range, matching the range `GameData.saveTemplate` accepts.
const int _minCourts = 1;
const int _maxCourts = 8;

/// The Sessions tab — round mode configuration, session capacity, court count,
/// and session templates.
///
/// Implements SESS-01 through SESS-06 from the UAT spec.
class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  /// Height of the template name field and the template buttons.
  static const double _controlHeight = 40;

  final TextEditingController _templateNameController = TextEditingController();

  /// Read from the setting, never cached: a template Load changes it too.
  bool get _isTimeBased =>
      PersistentSetting.instance.getGameType() == GameType.timeBased;

  @override
  void dispose() {
    _templateNameController.dispose();
    super.dispose();
  }

  void _toggleMode(bool timeBased) {
    PersistentSetting.instance.setGameType(
      timeBased ? GameType.timeBased : GameType.gameBased,
    );
    // GB-01: game-based mode has no countdown, so stop one already running.
    if (!timeBased) context.read<TimerData>().reset();
  }

  Future<void> _saveTemplate(GameData gameData) async {
    final saved = await gameData.saveTemplate(
      _templateNameController.text,
      _isTimeBased ? 1 : 0,
      PersistentSetting.instance.getGameDuration(),
      gameData.sessionCapacity,
      gameData.numberOfCourt,
    );
    // Only a template that was saved clears the field.
    if (saved && mounted) _templateNameController.clear();
  }

  /// Whether a change that reshuffles the lineup (court count, template Load)
  /// may go ahead.
  ///
  /// When a time-based round is running and the lineup holds players, the
  /// organizer first confirms throwing the round away — the same warning as
  /// Regenerate on the Dashboard.
  Future<bool> _confirmReshuffle(GameData gameData) async {
    final running = _isTimeBased && context.read<TimerData>().isRunning;
    if (!running || !gameData.wouldReshuffleLineup) return true;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDiscard(
      context,
      title: l10n.dashboard_discard_round_title,
      body: l10n.dashboard_discard_round_body,
      confirmLabel: l10n.sessions_reshuffle_confirm,
    );
    return confirmed && mounted;
  }

  Future<bool> _changeCourts(GameData gameData, int courts) async {
    if (!await _confirmReshuffle(gameData)) return false;
    gameData.setNumberOfCourt(courts);
    return true;
  }

  Future<void> _loadTemplate(
    GameData gameData,
    SessionTemplate template,
  ) async {
    final timerData = context.read<TimerData>();
    if (!await _confirmReshuffle(gameData)) return;
    gameData.loadTemplate(template);
    // The new round length must reach the countdown, running or not (F2).
    timerData.updateDuration(template.duration);
    // The template may switch to game-based mode (GB-01).
    if (GameMode.enabled && template.modeIndex != 1) timerData.reset();
  }

  @override
  Widget build(BuildContext context) {
    final gameData = context.watch<GameData>();
    // Watched so the mode description tracks duration edits and template loads.
    context.watch<PersistentSetting>();
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    return SingleChildScrollView(
      padding: AppSpacing.desktopPadding,
      child: isWide ? _buildWideLayout(gameData) : _buildNarrowLayout(gameData),
    );
  }

  Widget _buildWideLayout(GameData gameData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildRoundModeCard(gameData)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _buildTemplatesCard(gameData)),
      ],
    );
  }

  Widget _buildNarrowLayout(GameData gameData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRoundModeCard(gameData),
        const SizedBox(height: AppSpacing.lg),
        _buildTemplatesCard(gameData),
      ],
    );
  }

  // ── Round Mode Card ─────────────────────────────────────

  Widget _buildRoundModeCard(GameData gameData) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sessions_round_mode, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),

          // Toggle buttons and description (hidden in the release build).
          if (GameMode.enabled) ...[
            Row(
              children: [
                _ModeToggle(
                  label: l10n.sessions_game_based,
                  isSelected: !_isTimeBased,
                  onTap: () => _toggleMode(false),
                ),
                const SizedBox(width: AppSpacing.sm),
                _ModeToggle(
                  label: l10n.sessions_time_based,
                  isSelected: _isTimeBased,
                  onTap: () => _toggleMode(true),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _isTimeBased
                  ? l10n.sessions_time_based_description(
                      PersistentSetting.instance
                          .getGameDuration()
                          .toDisplayString(),
                    )
                  : l10n.sessions_game_based_description,
              style: AppTypography.body.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Duration control (time-based only)
          if (_isTimeBased) ...[
            const _DurationField(),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Session capacity
          _NumberField(
            fieldKey: const Key('sessions-capacity-field'),
            label: l10n.sessions_capacity,
            value: gameData.sessionCapacity,
            min: GameData.minSessionCapacity,
            max: _maxSessionCapacity,
            onChanged: (v) {
              gameData.setSessionCapacity(v);
              return true;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Courts count
          _NumberField(
            fieldKey: const Key('sessions-courts-field'),
            label: l10n.sessions_number_of_courts,
            value: gameData.numberOfCourt,
            min: _minCourts,
            max: _maxCourts,
            onChanged: (v) => _changeCourts(gameData, v),
          ),
        ],
      ),
    );
  }

  // ── Templates Card ──────────────────────────────────────

  Widget _buildTemplatesCard(GameData gameData) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.sessions_templates, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),

          // Save row
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('template-name'),
                  controller: _templateNameController,
                  decoration: InputDecoration(
                    hintText: l10n.sessions_template_name,
                    isDense: true,
                    border: const OutlineInputBorder(),
                    // 8 + 24 (16px text) + 8 = [_controlHeight].
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                height: _controlHeight,
                child: AppButton.primary(
                  label: l10n.sessions_save_current,
                  onPressed: () => _saveTemplate(gameData),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Saved templates list
          ...gameData.templates.map(
            (template) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          GameMode.enabled
                              ? l10n.sessions_template_summary(
                                  template.courts,
                                  template.modeIndex == 1 ? 'timed' : 'game',
                                  template.capacity,
                                )
                              : l10n.sessions_template_summary_no_mode(
                                  template.courts,
                                  template.capacity,
                                ),
                          style: AppTypography.helper.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: _controlHeight,
                    child: AppButton.secondary(
                      label: l10n.sessions_load,
                      onPressed: () => _loadTemplate(gameData, template),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A toggle pill for round mode selection.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: AppSpacing.tabButtonPadding,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentPrimary : AppColors.pillBg,
          borderRadius: AppRadii.mdRadius,
        ),
        child: Text(
          label,
          style: AppTypography.buttonSm.copyWith(
            color: isSelected
                ? AppColors.accentOnPrimary
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Exact `mm:ss` rotation duration control (SESS-02).
///
/// Two fields rather than one masked field: that is what gives native `Tab`
/// traversal from minutes to seconds, and lets each segment be selected whole
/// so the next keystroke replaces it.
class _DurationField extends StatefulWidget {
  const _DurationField();

  @override
  State<_DurationField> createState() => _DurationFieldState();
}

class _DurationFieldState extends State<_DurationField> {
  static const int _maxMinutes = 99;
  static const int _maxSeconds = Duration.secondsPerMinute - 1;

  final TextEditingController _minutesController = TextEditingController();
  final TextEditingController _secondsController = TextEditingController();
  final FocusNode _minutesFocus = FocusNode();
  final FocusNode _secondsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _writeFields(PersistentSetting.instance.getGameDuration());
    _minutesFocus.addListener(() => _onFocusChange(_minutesFocus));
    _secondsFocus.addListener(() => _onFocusChange(_secondsFocus));
  }

  @override
  void dispose() {
    _minutesController.dispose();
    _secondsController.dispose();
    _minutesFocus.dispose();
    _secondsFocus.dispose();
    super.dispose();
  }

  bool get _hasFocus => _minutesFocus.hasFocus || _secondsFocus.hasFocus;

  void _writeFields(Duration duration) {
    _minutesController.text = duration.inDisplayMinutes.toString().padLeft(
      2,
      '0',
    );
    _secondsController.text = duration.inDisplaySeconds.toString().padLeft(
      2,
      '0',
    );
  }

  void _onFocusChange(FocusNode node) {
    if (node.hasFocus) {
      _selectAll(node);
    } else {
      _commit();
    }
  }

  /// Highlights the whole segment so the next keystroke replaces it.
  void _selectAll(FocusNode node) {
    final controller = node == _minutesFocus
        ? _minutesController
        : _secondsController;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  /// Reads both fields, clamps them, and persists the result.
  ///
  /// A total of zero is rejected — a round cannot be zero long — and the
  /// fields fall back to the stored duration.
  void _commit() {
    final stored = PersistentSetting.instance.getGameDuration();
    final minutes = (int.tryParse(_minutesController.text) ?? 0).clamp(
      0,
      _maxMinutes,
    );
    final seconds = (int.tryParse(_secondsController.text) ?? 0).clamp(
      0,
      _maxSeconds,
    );
    final duration = Duration(minutes: minutes, seconds: seconds);

    if (duration == Duration.zero) {
      _writeFields(stored);
      return;
    }

    // Reflect the clamped values back into the fields.
    _writeFields(duration);
    if (_minutesFocus.hasFocus) _selectAll(_minutesFocus);
    if (_secondsFocus.hasFocus) _selectAll(_secondsFocus);

    if (duration == stored) return;
    PersistentSetting.instance.setGameDuration(duration);
    // Keep a round already in progress consistent with the new length.
    context.read<TimerData>().updateDuration(duration);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the duration changes elsewhere (e.g. loading a template).
    final duration = context.watch<PersistentSetting>().getGameDuration();
    if (!_hasFocus) _writeFields(duration);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.sessions_rotation_duration,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.inputBorder),
            borderRadius: AppRadii.mdRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _segment(
                key: const Key('duration-minutes'),
                controller: _minutesController,
                focusNode: _minutesFocus,
                label: l10n.sessions_minutes_short,
              ),
              const Text(':', style: AppTypography.cardTitle),
              _segment(
                key: const Key('duration-seconds'),
                controller: _secondsController,
                focusNode: _secondsFocus,
                label: l10n.sessions_seconds_short,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _segment({
    required Key key,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          child: TextField(
            key: key,
            controller: controller,
            focusNode: focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 2,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.cardTitle,
            // The app theme sets enabled and focused borders and padding.
            // Clear them, or each segment gets its own box and the padding
            // clips the second digit.
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
            ),
            // Tapping an already-focused field does not re-fire the focus
            // listener, so re-select the segment here too.
            onTap: () => _selectAll(focusNode),
            onSubmitted: (_) => _commit(),
          ),
        ),
        Text(
          label,
          style: AppTypography.helper.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

/// A labeled number input field.
class _NumberField extends StatefulWidget {
  const _NumberField({
    required this.fieldKey,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final Key fieldKey;
  final String label;
  final int value;

  /// Smallest accepted value. A lower entry is raised to this.
  final int min;

  /// Largest accepted value. A higher entry is lowered to this.
  final int max;

  /// Applies the new value. Returns `false` when it was declined (for
  /// example the organizer cancelled a confirmation).
  final FutureOr<bool> Function(int value) onChanged;

  @override
  State<_NumberField> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<_NumberField> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _committing = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
    // Committing on focus loss as well as on submit means an entry is never
    // silently dropped by clicking away from the field.
    _focus.addListener(() {
      if (!_focus.hasFocus) _commit();
    });
  }

  @override
  void didUpdateWidget(covariant _NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the text from outside if the field isn't focused,
    // to avoid overwriting user edits.
    if (widget.value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  /// Reads the field, clamps it to [_NumberField.min]…[_NumberField.max], and
  /// reflects the clamped number back so the box never shows a value the
  /// session did not accept.
  ///
  /// An empty or non-numeric entry counts as "below the minimum" and is
  /// raised to it (SESS-03). When [_NumberField.onChanged] declines the value,
  /// the field goes back to the value the session still holds.
  Future<void> _commit() async {
    // Submitting and then losing focus must not ask twice.
    if (_committing) return;
    final parsed = int.tryParse(_controller.text);
    final value = (parsed ?? widget.min).clamp(widget.min, widget.max);
    _controller.text = value.toString();
    if (value == widget.value) return;
    _committing = true;
    try {
      final accepted = await widget.onChanged(value);
      if (!accepted && mounted) _controller.text = widget.value.toString();
    } finally {
      _committing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.label,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            focusNode: _focus,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _commit(),
          ),
        ),
      ],
    );
  }
}
