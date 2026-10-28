import 'package:flutter/material.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/chat/chat_channel_display.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';

/// A conversation's avatar: the real photo when there is one, else the
/// resolved fallback icon (a neutral placeholder for 1:1/unknown, a tinted
/// mark on a colored circle for everything else — see
/// [resolveChannelDisplay]).
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    required this.avatarUrl,
    required this.iconAsset,
    required this.iconBackground,
    required this.size,
    super.key,
  });

  final String? avatarUrl;
  final String iconAsset;
  final ChatIconBackground iconBackground;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return ClipOval(
        child: Image.network(
          avatarUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }
    if (iconBackground == ChatIconBackground.none) {
      return SvgIcon(iconAsset, size: size);
    }
    final n = context.native;
    final background = switch (iconBackground) {
      ChatIconBackground.chatRoom => n.chatRoomBackground,
      ChatIconBackground.sportGreen => n.backgroundSolidGreen5,
      ChatIconBackground.none => null,
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: background),
      child: SvgIcon(iconAsset, size: size * 0.52, color: n.imagePrimeryColor),
    );
  }
}
