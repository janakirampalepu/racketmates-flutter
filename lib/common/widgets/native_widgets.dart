import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.subtitle,
    this.secondary,
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

  /// A line under the title (14 sp, secondary colour).
  final String? subtitle;

  /// Under the primary button, e.g. the "do it later" link.
  final Widget? secondary;

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        titleId == null
                            ? heading
                            : TestId(titleId!, child: heading),
                        if (subtitle != null)
                          Padding(
                            padding: EdgeInsets.only(top: sdp(4)),
                            child: Text(
                              subtitle!,
                              style: NativeText.regular(
                                sdp(14),
                                n.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
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
            if (secondary != null)
              Padding(
                padding: EdgeInsets.only(bottom: sdp(24)),
                child: secondary,
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
    this.inputFormatters,
    this.leading,
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
  final List<TextInputFormatter>? inputFormatters;

  /// Shown inside the box before the text, e.g. the country flag and dial
  /// code of a mobile number, followed by a divider.
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    final sdp = context.sdp;
    final field = TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: capitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
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
    );
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
              child: leading == null
                  ? field
                  : Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: sdp(4)),
                          child: leading,
                        ),
                        Container(
                          width: sdp(1),
                          height: sdp(32),
                          color: n.signupFieldViewColor,
                        ),
                        Expanded(child: field),
                      ],
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

/// The round "add a photo" button of the profile picture screens (native
/// `add_photo_profile`: a dashed outline, the add icon in the middle).
class DashedPhotoCircle extends StatelessWidget {
  const DashedPhotoCircle({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final n = context.native;
    return CustomPaint(
      size: Size.square(size),
      painter: _DashedCirclePainter(
        fill: n.iconBlack2,
        stroke: n.borderSolidPrimary,
      ),
      child: SizedBox.square(
        dimension: size,
        child: const Center(child: SvgIcon('ic_add_profile')),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  _DashedCirclePainter({required this.fill, required this.stroke});

  final Color fill;
  final Color stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(rect, Paint()..color = fill);
    final path = Path()..addOval(rect.deflate(1));
    final paint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    const dash = 10.0;
    const gap = 7.5;
    for (final metric in path.computeMetrics()) {
      for (double d = 0; d < metric.length; d += dash + gap) {
        canvas.drawPath(metric.extractPath(d, d + dash), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.fill != fill || old.stroke != stroke;
}
