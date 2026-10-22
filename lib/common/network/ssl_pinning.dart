import 'dart:io';

import 'package:dio/io.dart';
import 'package:flutter/services.dart';

/// A pinned CA certificate. Pins are CA public keys (SPKI SHA-256), never the
/// leaf: a normal renewal or reissue (even with a new leaf key) keeps working
/// as long as the same CA issues it. A connection is accepted when the
/// validated chain ends at any pinned certificate.
class PinnedCertificate {
  const PinnedCertificate({
    required this.name,
    required this.role,
    required this.spkiSha256,
    required this.assetPath,
    required this.validTo,
  });

  final String name;
  final String role;

  /// Base64 SPKI SHA-256 of the certificate's public key. Checked against the
  /// bundled PEM by `tool/verify_ssl_pins.sh` (run in CI via the `quality`
  /// lane), so the documented pin and the shipped certificate cannot drift.
  final String spkiSha256;
  final String assetPath;
  final int validTo;
}

/// Pin set for hosts served with the Sectigo DV chain
/// (leaf > DV R36 > Root R46). Values verified against the live chains of
/// api / api-qa / api-hotfix / api-regression / api-feature1.racketmatesapp.com
/// on 2026-10-22; the E36 backup comes from Sectigo's published certificate.
abstract final class SectigoPins {
  static const primaryIntermediate = PinnedCertificate(
    name: 'Sectigo Public Server Authentication CA DV R36',
    role: 'PRIMARY INTERMEDIATE',
    spkiSha256: 'a9khLOZJxlnJyrxstg/P+seiDCm+Yf3OsrXyFocBaI0=',
    assetPath: 'assets/certs/sectigo_dv_r36_intermediate.pem',
    validTo: 2036,
  );
  static const backupIntermediate = PinnedCertificate(
    name: 'Sectigo Public Server Authentication CA DV E36',
    role: 'BACKUP INTERMEDIATE',
    spkiSha256: 'ZSagvDzjltLkewXEBuDxIzpW/dpVw1Juvvmd0hhkzdY=',
    assetPath: 'assets/certs/sectigo_dv_e36_intermediate.pem',
    validTo: 2036,
  );
  static const root = PinnedCertificate(
    name: 'Sectigo Public Server Authentication Root R46',
    role: 'ROOT',
    spkiSha256: 'Douxi77vs4G+Ib/BogbTFymEYq0QSFXwSgVCaZcI09Q=',
    assetPath: 'assets/certs/sectigo_root_r46.pem',
    validTo: 2046,
  );

  static const all = [primaryIntermediate, backupIntermediate, root];
}

/// Builds the API HTTP adapter. The security context trusts ONLY the pinned
/// CA certificates (system roots are not used), so any chain that does not
/// end at a pin fails the TLS handshake. Use it for the Racketmates API Dio
/// only; other hosts (status page, CDN, SDKs) keep the system trust store.
///
/// Why not `network_security_config.xml` / `NSPinnedDomains`: Dart's
/// `HttpClient` does its own TLS and does not consult them. `Dio`'s
/// `validateCertificate` only sees the leaf and `badCertificateCallback` never
/// fires for validly signed certificates, so neither can express CA pinning.
Future<IOHttpClientAdapter> createPinnedAdapter(
  List<PinnedCertificate> pins, {
  AssetBundle? bundle,
}) async {
  if (pins.isEmpty) {
    throw ArgumentError.value(pins, 'pins', 'at least one pin is required');
  }
  final assets = bundle ?? rootBundle;
  final context = SecurityContext(withTrustedRoots: false);
  for (final pin in pins) {
    final data = await assets.load(pin.assetPath);
    context.setTrustedCertificatesBytes(data.buffer.asUint8List());
  }
  return pinnedAdapterForContext(context);
}

/// Adapter backed by an already-configured [SecurityContext] (also used by
/// tests with local TLS servers).
IOHttpClientAdapter pinnedAdapterForContext(SecurityContext context) =>
    IOHttpClientAdapter(createHttpClient: () => HttpClient(context: context));

/// Pin set for an environment, or empty when the environment is not pinned.
List<PinnedCertificate> pinsFor({required bool sslPinning}) =>
    sslPinning ? SectigoPins.all : const [];
