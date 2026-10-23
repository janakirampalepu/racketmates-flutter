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
