import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a web page outside the app (terms, privacy policy, store pages).
abstract class ExternalLinks {
  Future<void> open(Uri uri);
}

class UrlExternalLinks implements ExternalLinks {
  @override
  Future<void> open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final externalLinksProvider = Provider<ExternalLinks>(
  (ref) => UrlExternalLinks(),
);

/// Pages the subscription screens link to (native `AppConstants` and
/// `privacy_url`).
abstract final class SubscriptionLinks {
  /// Android shows Google Play's terms, as the native app does.
  static final termsAndroid = Uri.parse(
    'https://play.google.com/about/play-terms/index.html',
  );
  static final termsApple = Uri.parse(
    'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/',
  );
  // Android's own `privacy_url` string resource ("/privacypolicy", no
  // underscore) 404s on the live site — confirmed directly. iOS's
  // `racketmatesPrivacyUrl` ("/privacy_policy") is the one that actually
  // resolves; use that on both platforms.
  static final privacy = Uri.parse(
    'https://racketmatesapp.com/privacy_policy',
  );
  static final redeemAndroid = Uri.parse('https://play.google.com/redeem');
  static final manageAndroid = Uri.parse(
    'https://play.google.com/store/account/subscriptions',
  );
  static final manageApple = Uri.parse(
    'https://apps.apple.com/account/subscriptions',
  );
}
