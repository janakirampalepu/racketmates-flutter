import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/content/content_text.dart';
import 'package:racketmates/common/teams/team_labels.dart';
import 'package:racketmates/common/teams/team_models.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Casual/Competitive, side by side (native `teamEventType`/`txtCasual`+
/// `txtCompetitive`): a bordered rounded card per type, icon above label,
/// the selected one tinted/bordered in the brand color. Replaces a plain
/// `SegmentedButton` pill, which neither native app uses here.
class TeamTypeCards extends ConsumerWidget {
  const TeamTypeCards({
    required this.selected,
    required this.onSelect,
    required this.testIdFor,
    super.key,
  });

  final String? selected;
  final ValueChanged<String> onSelect;
  final String Function(String key) testIdFor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        for (final key in [TeamTypes.casual, TeamTypes.competitive])
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: key == TeamTypes.casual ? 8 : 0,
                left: key == TeamTypes.competitive ? 8 : 0,
              ),
              child: _TypeCard(
                testId: testIdFor(key),
                icon: key == TeamTypes.casual
                    ? 'ic_team_type_casual'
                    : 'ic_team_type_competitive',
                label: ref.refLabel(key, teamTypeLabel(l10n, key)),
                isSelected: selected == key,
                onTap: () => onSelect(selected == key ? '' : key),
              ),
            ),
          ),
      ],
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.testId,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String testId;
  final String icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      testId,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(sdp(12)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: sdp(16)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sdp(12)),
            border: Border.all(
              color: isSelected ? n.imagePrimeryColor : n.borderSolidPrimary,
              width: isSelected ? 1.5 : 1,
            ),
            color: isSelected
                ? n.imagePrimeryColor.withValues(alpha: 0.08)
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgIcon(icon, size: 22, color: n.imagePrimeryColor),
              SizedBox(height: sdp(16)),
              Text(label, style: TextStyle(color: n.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
