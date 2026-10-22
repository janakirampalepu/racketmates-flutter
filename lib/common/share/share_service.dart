import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

/// Opens the system share sheet.
abstract class ShareService {
  Future<void> shareText(String text);
}

class SystemShareService implements ShareService {
  @override
  Future<void> shareText(String text) async {
    await SharePlus.instance.share(ShareParams(text: text));
  }
}

final shareServiceProvider = Provider<ShareService>(
  (ref) => SystemShareService(),
);

/// The page that sends a friend to the right store (native `app_download_url`).
const appDownloadUrl = 'https://onelink.to/racketmates';
