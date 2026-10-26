import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/common/users/models/app_user.dart';
import 'package:racketmates/common/users/user_profile_provider.dart';
import 'package:racketmates/l10n/app_localizations.dart';

/// Shared by every screen with its own family-member avatar row (native
/// reuses the same `FamilyUsersPicker` from Home on the Teams list and
/// elsewhere).
abstract final class FamilyPickerTestIds {
  static const row = 'family_picker_row_widget';
  static const sheet = 'family_picker_sheet';
  static const save = 'family_picker_save';
  static String memberRow(int id) => 'family_picker_member_row_$id';
}

/// The signed-in user plus every one of their kids (native
/// `UserProfile.allUserDetails()`), parent first.
List<AppUser> familyMembers(AppUser user) => [
  user,
  ...user.children ?? const [],
];

/// Avatar row above a screen's content (native `layoutUsersList`, reused on
/// Home, the Teams list and elsewhere): hidden entirely when the signed-in
/// user has no kids, otherwise the parent plus up to two kids (native
/// `MAX_DISPLAY_CHILDS`) with an expand chevron. Tapping either opens the
/// multi-select picker, which filters every screen that reads
/// `selectedUserIdsProvider`.
class FamilyAvatarsRow extends ConsumerWidget {
  const FamilyAvatarsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider).value;
    if (user == null || (user.children ?? const []).isEmpty) {
      return const SizedBox.shrink();
    }
    final members = familyMembers(user);
    final selected = ref.watch(selectedUserIdsProvider).toSet();
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      FamilyPickerTestIds.row,
      child: Padding(
        padding: EdgeInsets.fromLTRB(sdp(12), sdp(4), sdp(12), sdp(4)),
        child: InkWell(
          borderRadius: BorderRadius.circular(sdp(20)),
          onTap: () => showFamilyUserPicker(context, ref),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: sdp(4)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final (i, member) in members.take(3).indexed)
                  Padding(
                    padding: EdgeInsets.only(left: i == 0 ? 0 : sdp(8)),
                    child: _FamilyAvatar(
                      member: member,
                      isSelected: selected.contains('${member.id}'),
                    ),
                  ),
                SizedBox(width: sdp(4)),
                Icon(Icons.expand_more, size: sdp(18), color: n.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FamilyAvatar extends StatelessWidget {
  const _FamilyAvatar({required this.member, required this.isSelected});

  final AppUser member;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    String first(String? s) =>
        (s == null || s.trim().isEmpty) ? '' : s.trim()[0].toUpperCase();
    final url = member.thumbnailAttachmentUrl ?? member.avatarFileAttachmentUrl;
    return Container(
      width: sdp(28),
      height: sdp(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: n.windowBackgroundColor,
        border: Border.all(
          color: isSelected ? n.colorPrimary : n.borderSolidPrimary,
          width: sdp(isSelected ? 2 : 1),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: (url == null || url.isEmpty)
          ? Text(
              '${first(member.firstName)}${first(member.lastName)}',
              style: NativeText.medium(sdp(11), n.mainTertiary),
            )
          : Image.network(url, fit: BoxFit.cover),
    );
  }
}

/// Native `FamilyUsersPicker`: a multi-select bottom sheet, parent always
/// included first; at least one user must stay selected to save.
Future<void> showFamilyUserPicker(BuildContext context, WidgetRef ref) async {
  final user = ref.read(userProfileProvider).value;
  if (user == null) return;
  final members = familyMembers(user);
  final current = ref.read(selectedUserIdsProvider).toSet();
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _FamilyPickerSheet(members: members, initiallySelected: current),
  );
}

class _FamilyPickerSheet extends ConsumerStatefulWidget {
  const _FamilyPickerSheet({
    required this.members,
    required this.initiallySelected,
  });

  final List<AppUser> members;
  final Set<String> initiallySelected;

  @override
  ConsumerState<_FamilyPickerSheet> createState() => _FamilyPickerSheetState();
}

class _FamilyPickerSheetState extends ConsumerState<_FamilyPickerSheet> {
  late final Set<String> _selected;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initiallySelected};
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final n = context.native;
    final sdp = context.sdp;
    return TestId(
      FamilyPickerTestIds.sheet,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(sdp(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.familyPickerTitle,
                style: NativeText.semibold(sdp(18), n.textPrimary),
              ),
              SizedBox(height: sdp(12)),
              for (final member in widget.members)
                _FamilyPickerRow(
                  member: member,
                  checked: _selected.contains('${member.id}'),
                  onChanged: (checked) => setState(() {
                    final id = '${member.id}';
                    if (checked) {
                      _selected.add(id);
                    } else {
                      _selected.remove(id);
                    }
                    _showError = false;
                  }),
                ),
              if (_showError)
                Padding(
                  padding: EdgeInsets.only(top: sdp(4), bottom: sdp(4)),
                  child: Text(
                    l10n.familyPickerSelectAtLeastOne,
                    style: NativeText.regular(sdp(12), n.noClubsColor),
                  ),
                ),
              SizedBox(height: sdp(12)),
              TestId(
                FamilyPickerTestIds.save,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(sdp(48)),
                    backgroundColor: n.colorPrimary,
                  ),
                  onPressed: () {
                    if (_selected.isEmpty) {
                      setState(() => _showError = true);
                      return;
                    }
                    ref
                        .read(selectedUserIdsProvider.notifier)
                        .select(_selected.toList());
                    Navigator.of(context).pop();
                  },
                  child: Text(l10n.familyPickerSaveAction),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FamilyPickerRow extends StatelessWidget {
  const _FamilyPickerRow({
    required this.member,
    required this.checked,
    required this.onChanged,
  });

  final AppUser member;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final name = [
      member.firstName,
      member.lastName,
    ].whereType<String>().join(' ');
    return TestId(
      FamilyPickerTestIds.memberRow(member.id ?? 0),
      child: InkWell(
        onTap: () => onChanged(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: NativeText.regular(sdp(14), n.textPrimary),
                ),
              ),
              Checkbox(
                value: checked,
                activeColor: n.colorPrimary,
                onChanged: (v) => onChanged(v ?? false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
