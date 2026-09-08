import 'package:flutter/material.dart';
import 'package:good_bad_board/design/design.dart';
import 'package:good_bad_board/model/elo.dart';

/// Vertical list of the 4 self-estimated skill tiers shown on the
/// self-registration page (REG-01, REG-03). Exactly one tier is always
/// selected — there is no "none" state.
class LevelSelector extends StatelessWidget {
  const LevelSelector({
    super.key,
    required this.selectedTier,
    required this.onTierSelected,
  });

  final SkillTier selectedTier;
  final ValueChanged<SkillTier> onTierSelected;

  static const Map<SkillTier, String> _descriptions = {
    SkillTier.amateur: 'New to badminton, or playing just for fun',
    SkillTier.intermediate: 'Comfortable rallying and knows the rules well',
    SkillTier.advanced: 'Plays regularly with strong technique and strategy',
    SkillTier.professional: 'Competitive or tournament-level player',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < SkillTier.values.length; i++) ...[
          _TierCard(
            tier: SkillTier.values[i],
            description: _descriptions[SkillTier.values[i]]!,
            selected: SkillTier.values[i] == selectedTier,
            onTap: () => onTierSelected(SkillTier.values[i]),
          ),
          if (i != SkillTier.values.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final SkillTier tier;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  static const _radius = BorderRadius.all(Radius.circular(9));

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.textPrimary : AppColors.cardBg;
    final border = selected ? AppColors.textPrimary : AppColors.cardBorder;
    final textColor = selected ? AppColors.white : AppColors.textPrimary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: _radius,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tier.label,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTypography.bodyFont,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textColor.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
