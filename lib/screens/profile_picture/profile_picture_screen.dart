import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:racketmates/app/router/app_routes.dart';
import 'package:racketmates/common/accessibility/test_id.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/widgets/step_scaffold.dart';
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
    return StepScaffold(
      rootId: ProfilePictureTestIds.root,
      titleId: ProfilePictureTestIds.title,
      title: l10n.profilePictureTitle,
      showBack: false,
      primaryLabel: l10n.uploadPhotoAction,
      primaryId: ProfilePictureTestIds.upload,
      loading: state.uploading,
      onPrimary: picked == null
          ? null
          : () async {
              final ok = await vm.upload();
              if (ok && context.mounted) context.go(AppRoutes.congratulations);
            },
      children: [
        Text(l10n.profilePictureHint),
        const SizedBox(height: 24),
        Center(
          child: picked == null
              ? TestId(
                  ProfilePictureTestIds.addPhoto,
                  child: const CircleAvatar(
                    radius: 64,
                    child: Icon(Icons.add_a_photo_outlined, size: 40),
                  ),
                )
              : TestId(
                  ProfilePictureTestIds.uploadedImage,
                  child: CircleAvatar(
                    radius: 64,
                    backgroundImage: FileImage(File(picked)),
                  ),
                ),
        ),
        const SizedBox(height: 24),
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
        const SizedBox(height: 12),
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
            padding: const EdgeInsets.only(top: 12),
            child: TestId(
              ProfilePictureTestIds.error,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  l10n.profilePictureUploadError,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ),
        const SizedBox(height: 12),
        TestId(
          ProfilePictureTestIds.doLaterButton,
          child: TextButton(
            onPressed: state.uploading
                ? null
                : () => context.go(AppRoutes.congratulations),
            child: Text(l10n.skipForNowAction),
          ),
        ),
      ],
    );
  }
}
