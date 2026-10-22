import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

enum PhotoSource { camera, gallery }

/// Picks a photo and returns its file path (null when cancelled). Wrapped so
/// screens and tests do not depend on the platform plugin.
abstract class PhotoPicker {
  Future<String?> pick(PhotoSource source);
}

/// Native apps compress profile photos to <= 2 MB at quality 80; asking the
/// platform picker for the same keeps uploads in that range.
class PlatformPhotoPicker implements PhotoPicker {
  PlatformPhotoPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<String?> pick(PhotoSource source) async {
    final file = await _picker.pickImage(
      source: source == PhotoSource.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    return file?.path;
  }
}

final photoPickerProvider = Provider<PhotoPicker>(
  (ref) => PlatformPhotoPicker(),
);
