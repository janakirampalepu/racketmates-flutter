import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';

/// One selectable sport row (native `SportsOptionView`/`SportsOptionsListView`,
/// shared by sign-up and team creation): a bordered rounded row with the
/// sport's icon, its name, and a custom checkbox square on the trailing
/// edge (filled + a white check when selected, just outlined otherwise —
/// not a Material `Checkbox`). Replaces the plain `CheckboxListTile` team
/// screens used to show here.
class SportSelectRow extends StatelessWidget {
  const SportSelectRow({
    required this.testId,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String testId;
  final String icon;
  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      testId,
      child: InkWell(
        onTap: () => onChanged(!selected),
        borderRadius: BorderRadius.circular(sdp(12)),
        child: Container(
          margin: EdgeInsets.only(bottom: sdp(8)),
          padding: EdgeInsets.symmetric(horizontal: sdp(12), vertical: sdp(12)),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(sdp(12)),
            border: Border.all(
              color: selected ? n.imagePrimeryColor : n.borderSolidPrimary,
              width: selected ? 1.5 : 1,
            ),
            color: selected
                ? n.imagePrimeryColor.withValues(alpha: 0.08)
                : null,
          ),
          child: Row(
            children: [
              SvgIcon(icon, size: 24, color: n.imagePrimeryColor),
              SizedBox(width: sdp(12)),
              Expanded(
                child: Text(label, style: TextStyle(color: n.textPrimary)),
              ),
              Container(
                width: sdp(20),
                height: sdp(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(sdp(2)),
                  color: selected ? n.imagePrimeryColor : null,
                  border: selected
                      ? null
                      : Border.all(color: n.borderSolidPrimary, width: 1.5),
                ),
                child: selected
                    ? Icon(Icons.check, size: sdp(14), color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
