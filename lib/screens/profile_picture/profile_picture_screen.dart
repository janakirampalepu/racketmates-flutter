import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/app/theme/native_theme.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/widgets/native_widgets.dart';
import 'package:racketmates/l10n/app_localizations.dart';
import 'package:racketmates/screens/profile_picture/profile_picture_test_ids.dart';
import 'package:racketmates/screens/profile_picture/profile_picture_view_model.dart';

/// Optional avatar after the account exists (native `ProfilePictureFragment`).
class ProfilePictureScreen extends ConsumerWidget {
  const ProfilePictureScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(profilePictureViewModelProvider);
    final vm = ref.read(profilePictureViewModelProvider.notifier);
    final picked = state.pickedPath;
    final n = context.native;
    final sdp = context.sdp;
    return SignUpScaffold(
      rootId: ProfilePictureTestIds.root,
      titleId: ProfilePictureTestIds.title,
      title: l10n.profilePictureTitle,
      titleGap: 6,
      subtitle: l10n.profilePictureHint,
      primaryLabel: l10n.uploadPhotoAction,
      primaryId: ProfilePictureTestIds.upload,
      loading: state.uploading,
      onPrimary: picked == null
          ? null
          : () async {
              final ok = await vm.upload();
              if (ok && context.mounted) context.go(AppRoutes.congratulations);
            },
      secondary: TestId(
        ProfilePictureTestIds.doLaterButton,
        child: InkWell(
          onTap: state.uploading
              ? null
              : () => context.go(AppRoutes.congratulations),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Center(
              child: Text(
                l10n.skipForNowAction,
                style: NativeText.bold(sdp(14), n.mainTertiary),
              ),
            ),
          ),
        ),
      ),
      children: [
        SizedBox(height: sdp(30)),
        Center(
          child: picked == null
              ? TestId(
                  ProfilePictureTestIds.addPhoto,
                  child: DashedPhotoCircle(size: sdp(160)),
                )
              : TestId(
                  ProfilePictureTestIds.uploadedImage,
                  child: SizedBox.square(
                    dimension: sdp(160),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: n.statsBgColorForNewUser,
                          ),
                        ),
                        ClipOval(
                          child: Image.file(
                            File(picked),
                            width: sdp(154),
                            height: sdp(154),
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          right: sdp(14),
                          bottom: sdp(10),
                          child: const SvgIcon('ic_photo_edit_icon'),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        SizedBox(height: sdp(24)),
        TestId(
          ProfilePictureTestIds.takePhoto,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_camera_outlined),
            onPressed: state.uploading
                ? null
                : () => vm.pick(PhotoSource.camera),
            label: Text(l10n.takePhotoAction),
          ),
        ),
        SizedBox(height: sdp(12)),
        TestId(
          ProfilePictureTestIds.chooseGallery,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.photo_library_outlined),
            onPressed: state.uploading
                ? null
                : () => vm.pick(PhotoSource.gallery),
            label: Text(l10n.chooseFromGalleryAction),
          ),
        ),
        if (state.uploadFailed)
          Padding(
            padding: EdgeInsets.only(top: sdp(12)),
            child: TestId(
              ProfilePictureTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.profilePictureUploadError,
                  style: NativeText.regular(sdp(12), n.statusColorsLightRed),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
