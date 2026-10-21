part of 'sessions_page.dart';

/// Sizes of the desktop Sessions board (canvas board "Sessions", R7-Q3).
abstract final class _DesktopSizes {
  /// The steppers and the value boxes are 52 px tall.
  static const double control = 52;

  /// Width of a value box (the `mm:ss` box, capacity, courts).
  static const double valueWidth = 128;

  /// A setting row with a note under its label.
  static const double settingRow = 92;

  /// The read-only changeover row.
  static const double plainRow = 64;

  /// A template row.
  static const double templateRow = 64;

  /// Template name field and "Save current".
  static const double saveControl = 44;

  /// "Load" and the delete button of a template row.
  static const double rowButton = 40;

  /// The value text: 28/600, tabular digits.
  static const TextStyle valueStyle = TextStyle(
    fontFamily: AppTypography.family,
    fontSize: AppTypography.sizeDisplay,
    fontWeight: AppTypography.semibold,
    height: 1.2,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// The "Round settings" card: duration, capacity, courts (only with
/// [CourtCount.editable]) and the fixed changeover. The round mode toggle is
/// not drawn: the release is time-based only (SESS-01, `GameMode.enabled`).
class _DesktopSettingsCard extends StatelessWidget {
  const _DesktopSettingsCard({
    required this.gameData,
    required this.onDuration,
    required this.onCapacity,
    required this.onCourts,
  });

  final GameData gameData;
  final ValueChanged<Duration> onDuration;
  final ValueChanged<int> onCapacity;
  final Future<bool> Function(int courts) onCourts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = PersistentSetting.instance.getGameDuration();
    const minute = Duration(minutes: 1);
    final capacity = gameData.sessionCapacity;
    final courts = gameData.numberOfCourt;
    final checkedIn = gameData.checkedInCount;

    return _DesktopCard(
      title: l10n.sessions_round_settings,
      children: [
        _SettingRow(
          label: l10n.sessions_round_duration,
          note: Consumer<TimerData>(
            builder: (context, timer, _) =>
                _NoteText(_durationNote(l10n, gameData, timer)),
          ),
          less: SessionsStepButton(
            key: const Key('sessions-duration-less'),
            symbol: '−',
            semanticsLabel: l10n.sessions_duration_less,
            onPressed: duration > minute
                ? () => onDuration(duration - minute)
                : null,
          ),
          value: const _DurationField(desktop: true),
          more: SessionsStepButton(
            key: const Key('sessions-duration-more'),
            symbol: '+',
            semanticsLabel: l10n.sessions_duration_more,
            onPressed: duration < _maxDuration
                ? () => onDuration(duration + minute)
                : null,
          ),
        ),
        _SettingRow(
          label: l10n.sessions_capacity,
          note: _NoteText(
            capacity < checkedIn
                ? l10n.sessions_capacity_note_over(checkedIn)
                : l10n.sessions_capacity_note(
                    checkedIn,
                    GameData.minSessionCapacity,
                  ),
          ),
          less: SessionsStepButton(
            key: const Key('sessions-capacity-less'),
            symbol: '−',
            semanticsLabel: l10n.sessions_capacity_less,
            onPressed: capacity > GameData.minSessionCapacity
                ? () => onCapacity(capacity - 1)
                : null,
          ),
          value: _NumberField(
            desktop: true,
            fieldKey: const Key('sessions-capacity-field'),
            label: l10n.sessions_capacity,
            value: capacity,
            min: GameData.minSessionCapacity,
            max: _maxSessionCapacity,
            onChanged: (value) {
              onCapacity(value);
              return true;
            },
          ),
          more: SessionsStepButton(
            key: const Key('sessions-capacity-more'),
            symbol: '+',
            semanticsLabel: l10n.sessions_capacity_more,
            onPressed: capacity < _maxSessionCapacity
                ? () => onCapacity(capacity + 1)
                : null,
          ),
        ),
        // Hidden in the release (R45-36, R7-Q3).
        if (CourtCount.editable)
          _SettingRow(
            label: l10n.sessions_number_of_courts,
            note: _NoteText(l10n.sessions_courts_note),
            less: SessionsStepButton(
              key: const Key('sessions-courts-less'),
              symbol: '−',
              semanticsLabel: l10n.sessions_courts_less,
              onPressed: courts > _minCourts
                  ? () => onCourts(courts - 1)
                  : null,
            ),
            value: _CourtsValue(
              courts: courts,
              label: l10n.sessions_number_of_courts,
            ),
            more: SessionsStepButton(
              key: const Key('sessions-courts-more'),
              symbol: '+',
              semanticsLabel: l10n.sessions_courts_more,
              onPressed: courts < _maxCourts
                  ? () => onCourts(courts + 1)
                  : null,
            ),
          ),
        // Read-only (R3-Q7).
        Container(
          constraints: const BoxConstraints(minHeight: _DesktopSizes.plainRow),
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  l10n.sessions_changeover,
                  style: AppTypography.subtitle,
                ),
              ),
              Text(
                l10n.sessions_changeover_value(
                  TimerData.changeoverLength.inSeconds,
                ),
                style: AppTypography.subtitle.copyWith(
                  fontWeight: AppTypography.regular,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// When the new length takes effect (SESS-02, R9-Q6): at once while round
  /// n has its clock, else from the next round to start.
  static String _durationNote(
    AppLocalizations l10n,
    GameData gameData,
    TimerData timer,
  ) {
    final paused = gameData.phase == RoundPhase.paused;
    final fromRound = paused ? gameData.pausedFrom : gameData.phase;
    return switch (fromRound) {
      RoundPhase.running when timer.remaining > Duration.zero =>
        l10n.sessions_duration_note_left(
          gameData.roundNumber,
          timer.remainingLabel,
        ),
      RoundPhase.running || RoundPhase.timeUp =>
        l10n.sessions_duration_note_next(gameData.roundNumber + 1),
      RoundPhase.changeover => l10n.sessions_duration_note_next(
        gameData.displayRoundNumber,
      ),
      _ => l10n.sessions_duration_note_ready,
    };
  }
}

/// The "Session templates" card: the save block and the list, which
/// scrolls inside the card.
class _DesktopTemplatesCard extends StatelessWidget {
  const _DesktopTemplatesCard({
    required this.gameData,
    required this.nameController,
    required this.onSave,
    required this.onLoad,
    required this.onDelete,
  });

  final GameData gameData;
  final TextEditingController nameController;
  final Future<void> Function() onSave;
  final ValueChanged<SessionTemplate> onLoad;
  final ValueChanged<SessionTemplate> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final templates = gameData.templates;
    final current = templateSummary(
      l10n,
      duration: PersistentSetting.instance.getGameDuration(),
      courts: gameData.numberOfCourt,
      capacity: gameData.sessionCapacity,
    );

    return _DesktopCard(
      title: l10n.sessions_templates,
      expandLast: true,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: AppSpacing.lg,
          ),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.sessions_save_settings_label,
                style: AppTypography.statLabel.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: nameController,
                builder: (context, value, _) {
                  final blank = value.text.trim().isEmpty;
                  return Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: _DesktopSizes.saveControl,
                          child: TextField(
                            key: const Key('template-name'),
                            controller: nameController,
                            style: AppTypography.subtitle.copyWith(
                              fontWeight: AppTypography.regular,
                            ),
                            textAlignVertical: TextAlignVertical.center,
                            // Fill the 44 px box.
                            expands: true,
                            maxLines: null,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: l10n.sessions_template_name,
                              isDense: true,
                              filled: true,
                              fillColor: AppColors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                              ),
                              border: const OutlineInputBorder(
                                borderRadius: AppRadii.mdRadius,
                                borderSide: BorderSide(
                                  color: AppColors.controlBorder,
                                ),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderRadius: AppRadii.mdRadius,
                                borderSide: BorderSide(
                                  color: AppColors.controlBorder,
                                ),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderRadius: AppRadii.mdRadius,
                                borderSide: BorderSide(
                                  color: AppColors.focusOnLight,
                                  width: 3,
                                ),
                              ),
                            ),
                            onSubmitted: (_) {
                              if (nameController.text.trim().isNotEmpty) {
                                onSave();
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SessionsSaveButton(
                        key: const Key('sessions-save-template'),
                        label: l10n.sessions_save_current,
                        onPressed: blank ? null : onSave,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 6),
              _NoteText(l10n.sessions_saves_summary(current)),
            ],
          ),
        ),
        Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.cardBorder)),
          ),
          child: templates.isEmpty
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _NoteText(l10n.sessions_no_templates),
                  ),
                )
              : ListView.builder(
                  key: const Key('sessions-template-list'),
                  padding: EdgeInsets.zero,
                  itemCount: templates.length,
                  itemBuilder: (context, index) => _TemplateRow(
                    template: templates[index],
                    onLoad: onLoad,
                    onDelete: onDelete,
                  ),
                ),
        ),
      ],
    );
  }
}

/// The summary of a template on the desktop board: "10 min · 4 courts ·
/// cap 20". With the court count fixed ([CourtCount.editable] off) the
/// courts are left out, because a Load keeps 4 courts (R45-36).
String templateSummary(
  AppLocalizations l10n, {
  required Duration duration,
  required int courts,
  required int capacity,
}) {
  final length = roundDurationText(l10n, duration);
  return CourtCount.editable
      ? l10n.sessions_template_summary_duration(length, courts, capacity)
      : l10n.sessions_template_summary_duration_no_courts(length, capacity);
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({
    required this.template,
    required this.onLoad,
    required this.onDelete,
  });

  final SessionTemplate template;
  final ValueChanged<SessionTemplate> onLoad;
  final ValueChanged<SessionTemplate> onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minHeight: _DesktopSizes.templateRow),
      padding: const EdgeInsets.fromLTRB(
        20,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.subtitle,
                ),
                const SizedBox(height: 2),
                _NoteText(
                  templateSummary(
                    l10n,
                    duration: template.duration,
                    courts: template.courts,
                    capacity: template.capacity,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Semantics(
            label: l10n.sessions_load_named(template.name),
            button: true,
            excludeSemantics: true,
            child: CourtsButton(
              key: Key('template-load-${template.id}'),
              label: l10n.sessions_load,
              onPressed: () => onLoad(template),
              height: _DesktopSizes.rowButton,
              background: AppColors.pageBg,
              foreground: AppColors.textPrimary,
              ringColor: AppColors.focusOnLight,
              borderColor: AppColors.controlBorderSoft,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _DeleteButton(
            key: Key('template-delete-${template.id}'),
            label: l10n.sessions_delete_named(template.name),
            onPressed: () => onDelete(template),
          ),
        ],
      ),
    );
  }
}

/// The 40 × 40 delete button of a template row: 1 px `#8f826e`, red bin.
class _DeleteButton extends StatefulWidget {
  const _DeleteButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  State<_DeleteButton> createState() => _DeleteButtonState();
}

class _DeleteButtonState extends State<_DeleteButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.label,
      excludeFromSemantics: true,
      child: Semantics(
        label: widget.label,
        button: true,
        excludeSemantics: true,
        child: FocusRing(
          focused: _focused,
          color: AppColors.focusOnLight,
          radius: AppRadii.md,
          child: Material(
            color: AppColors.pageBg,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.mdRadius,
              side: BorderSide(color: AppColors.controlBorderSoft),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: AppRadii.mdRadius,
              child: const SizedBox.square(
                dimension: _DesktopSizes.rowButton,
                child: Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: AppColors.error,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A card of the desktop board: `#fbf6ee`, 1 px `#e4d8c4`, radius 12, a
/// 20/600 title. With [expandLast] the last child fills the card height.
class _DesktopCard extends StatelessWidget {
  const _DesktopCard({
    required this.title,
    required this.children,
    this.expandLast = false,
  });

  final String title;
  final List<Widget> children;
  final bool expandLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: AppRadii.xlRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              20,
              AppSpacing.lg,
              20,
              AppSpacing.md,
            ),
            child: Semantics(
              header: true,
              child: Text(title, style: AppTypography.title),
            ),
          ),
          for (var i = 0; i < children.length; i++)
            if (expandLast && i == children.length - 1)
              Expanded(child: children[i])
            else
              children[i],
        ],
      ),
    );
  }
}

/// One setting row: the label and its note, then "−", the value, "+".
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.note,
    required this.less,
    required this.value,
    required this.more,
  });

  final String label;
  final Widget note;
  final Widget less;
  final Widget value;
  final Widget more;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: _DesktopSizes.settingRow),
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.subtitle),
                const SizedBox(height: AppSpacing.xs),
                note,
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          less,
          const SizedBox(width: AppSpacing.lg),
          value,
          const SizedBox(width: AppSpacing.lg),
          more,
        ],
      ),
    );
  }
}

/// A 14/400 muted note.
class _NoteText extends StatelessWidget {
  const _NoteText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.body.copyWith(color: AppColors.textMuted),
    );
  }
}

/// The court count: read-only, changed by the steppers only. A polite live
/// region, so a screen reader hears the new count.
class _CourtsValue extends StatelessWidget {
  const _CourtsValue({required this.courts, required this.label});

  final int courts;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const Key('sessions-courts-value'),
      label: label,
      value: '$courts',
      liveRegion: true,
      excludeSemantics: true,
      child: Container(
        width: _DesktopSizes.valueWidth,
        height: _DesktopSizes.control,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(color: AppColors.controlBorder),
          borderRadius: AppRadii.lgRadius,
        ),
        child: Text('$courts', style: _DesktopSizes.valueStyle),
      ),
    );
  }
}

/// A 52 × 52 "−" or "+" stepper of the desktop board: 1 px `#8f826e`,
/// 28/600 symbol, `#c2410c` focus ring. With no [onPressed] it is dimmed to
/// 45 % and does nothing (canvas `button:disabled`).
class SessionsStepButton extends StatefulWidget {
  const SessionsStepButton({
    super.key,
    required this.symbol,
    required this.semanticsLabel,
    required this.onPressed,
  });

  final String symbol;
  final String semanticsLabel;
  final VoidCallback? onPressed;

  @override
  State<SessionsStepButton> createState() => _SessionsStepButtonState();
}

class _SessionsStepButtonState extends State<SessionsStepButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    return Semantics(
      label: widget.semanticsLabel,
      button: true,
      enabled: enabled,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: FocusRing(
          focused: _focused,
          color: AppColors.focusOnLight,
          radius: AppRadii.lg,
          child: Material(
            color: AppColors.pageBg,
            shape: const RoundedRectangleBorder(
              borderRadius: AppRadii.lgRadius,
              side: BorderSide(color: AppColors.controlBorderSoft),
            ),
            child: InkWell(
              onTap: widget.onPressed,
              onFocusChange: (value) => setState(() => _focused = value),
              borderRadius: AppRadii.lgRadius,
              child: SizedBox.square(
                dimension: _DesktopSizes.control,
                child: Center(
                  child: Text(
                    widget.symbol,
                    style: _DesktopSizes.valueStyle.copyWith(height: 1),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The orange "Save current" button (44 px), the one primary button of the
/// tab. With no [onPressed] (a blank name, SESS-05) it is dimmed to 45 %.
class SessionsSaveButton extends StatelessWidget {
  const SessionsSaveButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: CourtsButton(
          label: label,
          onPressed: onPressed,
          height: _DesktopSizes.saveControl,
          background: AppColors.accentPrimary,
          foreground: AppColors.accentOnPrimary,
          ringColor: AppColors.focusOnLight,
          horizontalPadding: 20,
        ),
      ),
    );
  }
}
