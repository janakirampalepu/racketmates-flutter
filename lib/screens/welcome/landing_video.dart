import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

/// Tests switch the background video off (no video plugin there).
final landingVideoEnabledProvider = Provider<bool>((ref) => true);

/// The landing background (native `PlayerView`): the light or dark brand
/// video, muted and looping, filling the screen. While it loads, or when it
/// cannot play, the plain window colour shows.
class LandingVideo extends ConsumerStatefulWidget {
  const LandingVideo({super.key});

  @override
  ConsumerState<LandingVideo> createState() => _LandingVideoState();
}

class _LandingVideoState extends ConsumerState<LandingVideo> {
  VideoPlayerController? _controller;
  Brightness? _loaded;

  Future<void> _load(Brightness brightness) async {
    _loaded = brightness;
    final old = _controller;
    final next = VideoPlayerController.asset(
      brightness == Brightness.dark
          ? 'assets/video/racketmates_dark.mp4'
          : 'assets/video/racketmates_light.mp4',
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    );
    try {
      await next.initialize();
      await next.setLooping(true);
      await next.setVolume(0);
      await next.play();
    } on Object {
      await next.dispose();
      return;
    }
    if (!mounted || _loaded != brightness) {
      await next.dispose();
      return;
    }
    setState(() => _controller = next);
    await old?.dispose();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(landingVideoEnabledProvider)) return const SizedBox.shrink();
    final brightness = Theme.of(context).brightness;
    if (_loaded != brightness) _load(brightness);
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return ExcludeSemantics(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: c.value.size.width,
            height: c.value.size.height,
            child: VideoPlayer(c),
          ),
        ),
      ),
    );
  }
}
