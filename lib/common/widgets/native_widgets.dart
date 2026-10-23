import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/app/theme/native_theme.dart';

/// A vector icon ported from the native drawables (`assets/icons/<name>.svg`,
/// see `tool/port_android_resources.py`). [color] repaints it (native tints
/// icons with theme colours).
class SvgIcon extends StatelessWidget {
  const SvgIcon(this.name, {this.size, this.color, super.key});

  final String name;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    excludeFromSemantics: true,
    colorFilter: color == null
        ? null
        : ColorFilter.mode(color!, BlendMode.srcIn),
  );
}

/// The toolbar of the sign-up screens (native `toolbar_layout`): the window
/// colour, the left arrow, and a hairline under it (`signup_view_color`).
class NativeAuthScaffold extends StatelessWidget {
  const NativeAuthScaffold({
    required this.body,
    this.onBack,
    this.backId,
    super.key,
  });

  final Widget body;
  final VoidCallback? onBack;
  final String? backId;

  Widget _wrap(String? id, Widget child) =>
      id == null ? child : TestId(id, child: child);

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    return Scaffold(
      backgroundColor: n.windowBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: onBack == null
            ? null
            : _wrap(
                backId,
                IconButton(
                  tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                  icon: SvgIcon(
                    'ic_actionbar_left_arrow',
                    color: n.textPrimary,
                  ),
                  onPressed: onBack,
                ),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: n.signupViewColor),
        ),
      ),
      body: body,
    );
  }
}

/// The layout shared by the sign-up screens (native `fragment_detail_signup`,
/// `fragment_role_selection`, `fragment_sports_list`): toolbar with a hairline,
/// a left-aligned 22 sdp title, 12 sdp margins and the lime *Next* button.
class SignUpScaffold extends StatelessWidget {
  const SignUpScaffold({
    required this.rootId,
    required this.title,
    required this.children,
    this.titleId,
    this.backId,
    this.onBack,
    this.primaryLabel,
    this.primaryId,
    this.onPrimary,
    this.loading = false,
    this.titleGap = 24,
    super.key,
  });

  final String rootId;
  final String title;
  final String? titleId;
  final String? backId;
  final VoidCallback? onBack;
  final List<Widget> children;
  final String? primaryLabel;
  final String? primaryId;
  final VoidCallback? onPrimary;
  final bool loading;

  /// The space under the title in sdp (14 on the details form, 24 on lists).
  final double titleGap;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final heading = Semantics(
      header: true,
      child: Text(title, style: NativeText.semibold(sdp(22), n.textPrimary)),
    );
    return NativeAuthScaffold(
      onBack: onBack,
      backId: backId,
      body: TestId(
        rootId,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(sdp(12)),
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: sdp(14),
                      bottom: sdp(titleGap),
                    ),
                    child: titleId == null
                        ? heading
                        : TestId(titleId!, child: heading),
                  ),
                  ...children,
                ],
              ),
            ),
            if (primaryLabel != null)
              Padding(
                padding: EdgeInsets.all(sdp(12)),
                child: SafeArea(
                  top: false,
                  child: TestId(
                    primaryId ?? '${rootId}_primary_button',
                    child: FilledButton(
                      onPressed: loading ? null : onPrimary,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(sdp(50)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sdp(12)),
                        ),
                        textStyle: NativeText.bold(sdp(14), n.black),
                      ),
                      child: loading
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(primaryLabel!),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A labelled text field in the native style (`EditFieldNameStyle`,
/// `EditFieldViewStyle`, `bg_edit_fields`, `EditFieldInLineMessageStyle`).
class NativeTextField extends StatelessWidget {
  const NativeTextField({
    required this.label,
    required this.controller,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.capitalization = TextCapitalization.words,
    this.autofillHints,
    this.maxLength,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.only(top: sdp(6)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: sdp(6), bottom: sdp(2)),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: NativeText.regular(sdp(12), n.textSecondary),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: sdp(4)),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(sdp(10)),
                border: Border.all(
                  color: error == null
                      ? n.borderSolidPrimary
                      : n.statusColorsLightRed,
                  width: sdp(1),
                ),
              ),
              child: TextField(
                controller: controller,
                keyboardType: keyboardType,
                textInputAction: textInputAction,
                textCapitalization: capitalization,
                autofillHints: autofillHints,
                maxLength: maxLength,
                maxLines: 1,
                cursorColor: n.textPrimary,
                style: NativeText.regular(sdp(12), n.textPrimary),
                onSubmitted: onSubmitted,
                decoration: InputDecoration(
                  isDense: true,
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(sdp(14)),
                ),
              ),
            ),
          ),
          if (error != null)
            Padding(
              padding: EdgeInsets.all(sdp(4)),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgIcon('ic_error_info', color: n.statusColorsLightRed),
                    SizedBox(width: sdp(8)),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          error!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: NativeText.regular(
                            sdp(12),
                            n.statusColorsLightRed,
                          ),
                        ),
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

/// A selectable row with a picture, a title and a checkbox: the role and
/// sport rows (native `roles_bg` / `role_selected_bg`: a faint lime gradient
/// with a grey outline, lime when chosen).
class NativeChoiceCard extends StatelessWidget {
  const NativeChoiceCard({
    required this.icon,
    required this.iconSize,
    required this.title,
    required this.selected,
    required this.onChanged,
    this.subtitle,
    this.padding = 10,
    this.titleSize = 14,
    super.key,
  });

  final String icon;
  final double iconSize;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onChanged;
  final double padding;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    return Padding(
      padding: EdgeInsets.only(bottom: sdp(12)),
      child: Semantics(
        container: true,
        checked: selected,
        child: InkWell(
          onTap: onChanged,
          borderRadius: BorderRadius.circular(sdp(12)),
          child: Ink(
            padding: EdgeInsets.all(sdp(padding)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(sdp(12)),
              gradient: LinearGradient(
                colors: [
                  n.rowStartGradient,
                  n.rowCenterGradient,
                  n.rowEndGradient,
                ],
              ),
              border: Border.all(
                color: selected ? n.colorPrimary : n.statusColorsDarkGray,
                width: sdp(1),
              ),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  SvgIcon(icon, size: sdp(iconSize)),
                  SizedBox(width: sdp(10)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: NativeText.bold(sdp(titleSize), n.textPrimary),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(top: sdp(4)),
                            child: Text(
                              subtitle!,
                              style: NativeText.regular(
                                sdp(10),
                                n.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  ExcludeSemantics(
                    child: Checkbox(
                      value: selected,
                      activeColor: n.textcolor,
                      checkColor: n.windowBackgroundColor,
                      side: BorderSide(color: n.textcolor, width: 2),
                      onChanged: (_) => onChanged(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
