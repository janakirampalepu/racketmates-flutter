import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/auth/session_controller.dart';
import 'package:racketmates/common/auth/session_state.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/media/image_picker_service.dart';
import 'package:racketmates/common/users/user_repository.dart';
import 'package:racketmates/screens/profile_picture/profile_picture_state.dart';

class ProfilePictureViewModel extends Notifier<ProfilePictureState> {
  @override
  ProfilePictureState build() => const ProfilePictureState();

  Future<void> pick(PhotoSource source) async {
    final path = await ref.read(photoPickerProvider).pick(source);
    if (path != null) {
      state = ProfilePictureState(pickedPath: path);
    }
  }

  /// Uploads the picked photo for the signed-in user. True on success.
  Future<bool> upload() async {
    final path = state.pickedPath;
    final session = ref.read(sessionControllerProvider);
    final id = session is SignedIn ? session.token.user?.id : null;
    if (path == null || id == null || state.uploading) return false;
    state = state.copyWith(uploading: true, uploadFailed: false);
    try {
      await ref.read(userRepositoryProvider).uploadAvatar(id, path);
      state = state.copyWith(uploading: false);
      return true;
    } on AppFailure {
      state = state.copyWith(uploading: false, uploadFailed: true);
      return false;
    }
  }
}

final profilePictureViewModelProvider =
    NotifierProvider.autoDispose<ProfilePictureViewModel, ProfilePictureState>(
      ProfilePictureViewModel.new,
    );
