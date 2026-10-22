class ProfilePictureState {
  const ProfilePictureState({
    this.pickedPath,
    this.uploading = false,
    this.uploadFailed = false,
  });

  final String? pickedPath;
  final bool uploading;
  final bool uploadFailed;

  ProfilePictureState copyWith({
    String? pickedPath,
    bool? uploading,
    bool? uploadFailed,
  }) => ProfilePictureState(
    pickedPath: pickedPath ?? this.pickedPath,
    uploading: uploading ?? this.uploading,
    uploadFailed: uploadFailed ?? this.uploadFailed,
  );
}
