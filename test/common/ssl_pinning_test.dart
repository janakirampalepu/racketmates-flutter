import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/app/config/app_environment.dart';
import 'package:racketmates/common/network/ssl_pinning.dart';

Future<bool> _hasOpenssl() async {
  try {
    return (await Process.run('openssl', ['version'])).exitCode == 0;
  } on ProcessException {
    return false;
  }
}

/// Test PKI generated at test time (no key material is committed):
/// root CA > intermediate CA > localhost leaf, mirroring leaf > DV R36 > R46.
class _TestPki {
  _TestPki(this.dir);

  final Directory dir;
  String path(String name) => '${dir.path}/$name';

  Future<void> _openssl(List<String> args) async {
    final r = await Process.run('openssl', args, workingDirectory: dir.path);
    expect(r.exitCode, 0, reason: '${r.stderr}');
  }

  Future<void> generate() async {
    File(path('ca.ext')).writeAsStringSync(
      'basicConstraints=critical,CA:TRUE\nkeyUsage=critical,keyCertSign,cRLSign\n',
    );
    File(path('leaf.ext')).writeAsStringSync(
      'basicConstraints=CA:FALSE\nsubjectAltName=DNS:localhost,IP:127.0.0.1\n'
      'extendedKeyUsage=serverAuth\n',
    );
    await _openssl([
      'req',
      '-x509',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-days',
      '1',
      '-keyout',
      'root.key',
      '-out',
      'root.pem',
      '-subj',
      '/CN=Test Root',
      '-addext',
      'basicConstraints=critical,CA:TRUE',
      '-addext',
      'keyUsage=critical,keyCertSign,cRLSign',
    ]);
    await _openssl([
      'req',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      'int.key',
      '-out',
      'int.csr',
      '-subj',
      '/CN=Test Intermediate',
    ]);
    await _openssl([
      'x509',
      '-req',
      '-in',
      'int.csr',
      '-CA',
      'root.pem',
      '-CAkey',
      'root.key',
      '-CAcreateserial',
      '-days',
      '1',
      '-out',
      'int.pem',
      '-extfile',
      'ca.ext',
    ]);
    await _openssl([
      'req',
      '-newkey',
      'rsa:2048',
      '-nodes',
      '-keyout',
      'leaf.key',
      '-out',
      'leaf.csr',
      '-subj',
      '/CN=localhost',
    ]);
    await _openssl([
      'x509',
      '-req',
      '-in',
      'leaf.csr',
      '-CA',
      'int.pem',
      '-CAkey',
      'int.key',
      '-CAcreateserial',
      '-days',
      '1',
      '-out',
      'leaf.pem',
      '-extfile',
      'leaf.ext',
    ]);
    File(path('chain.pem')).writeAsStringSync(
      File(path('leaf.pem')).readAsStringSync() +
          File(path('int.pem')).readAsStringSync(),
    );
  }

  SecurityContext trusting(String file) =>
      SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(File(path(file)).readAsBytesSync());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => HttpOverrides.global = null); // allow loopback TLS in tests

  group('pin set', () {
    test('pins CA public keys only: primary + backup intermediate + root', () {
      expect(SectigoPins.all.map((p) => p.role), [
        'PRIMARY INTERMEDIATE',
        'BACKUP INTERMEDIATE',
        'ROOT',
      ]);
      expect(SectigoPins.all.map((p) => p.spkiSha256).toSet(), hasLength(3));
    });

    test('documented SPKI values', () {
      expect(
        SectigoPins.primaryIntermediate.spkiSha256,
        'a9khLOZJxlnJyrxstg/P+seiDCm+Yf3OsrXyFocBaI0=',
      );
      expect(
        SectigoPins.backupIntermediate.spkiSha256,
        'ZSagvDzjltLkewXEBuDxIzpW/dpVw1Juvvmd0hhkzdY=',
      );
      expect(
        SectigoPins.root.spkiSha256,
        'Douxi77vs4G+Ib/BogbTFymEYq0QSFXwSgVCaZcI09Q=',
      );
    });

    test('hosted environments are pinned; dev and local are not', () {
      final pinned = AppEnvironment.values
          .where((e) => e.sslPinning)
          .map((e) => e.id);
      expect(
        pinned,
        unorderedEquals([
          'production',
          'hotfix',
          'qa',
          'regression',
          'staging',
        ]),
      );
      expect(pinsFor(sslPinning: false), isEmpty);
      expect(pinsFor(sslPinning: true), SectigoPins.all);
    });

    test('every bundled certificate loads as a trust anchor', () async {
      for (final pin in SectigoPins.all) {
        final data = await rootBundle.load(pin.assetPath);
        expect(
          () =>
              SecurityContext(withTrustedRoots: false)
                ..setTrustedCertificatesBytes(data.buffer.asUint8List()),
          returnsNormally,
          reason: pin.name,
        );
      }
      await expectLater(createPinnedAdapter(SectigoPins.all), completes);
    });

    test('createPinnedAdapter rejects an empty pin list', () {
      expect(() => createPinnedAdapter(const []), throwsArgumentError);
    });
  });

  group('enforcement against a local TLS server', () {
    late Directory dir;
    late HttpServer server;
    late _TestPki pki;
    late bool openssl;

    setUp(() async {
      openssl = await _hasOpenssl();
      if (!openssl) return;
      dir = await Directory.systemTemp.createTemp('pin_test');
      pki = _TestPki(dir);
      await pki.generate();
      final serverContext = SecurityContext()
        ..useCertificateChain(pki.path('chain.pem'))
        ..usePrivateKey(pki.path('leaf.key'));
      server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv4,
        0,
        serverContext,
      );
      server.listen((request) {
        request.response
          ..statusCode = 200
          ..write('ok')
          ..close();
      });
    });

    tearDown(() async {
      if (!openssl) return;
      await server.close(force: true);
      await dir.delete(recursive: true);
    });

    Dio client(SecurityContext context) =>
        Dio(BaseOptions(baseUrl: 'https://127.0.0.1:${server.port}'))
          ..httpClientAdapter = pinnedAdapterForContext(context);

    test('accepts when only the intermediate is pinned', () async {
      final response = await client(pki.trusting('int.pem')).get<String>('/');
      expect(response.statusCode, 200);
    });

    test('accepts when only the root is pinned', () async {
      final response = await client(pki.trusting('root.pem')).get<String>('/');
      expect(response.statusCode, 200);
    });

    test(
      'rejects a chain that does not end at any pin (negative test)',
      () async {
        final data = await rootBundle.load(
          SectigoPins.primaryIntermediate.assetPath,
        );
        final context = SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificatesBytes(data.buffer.asUint8List());
        await expectLater(
          client(context).get<String>('/'),
          throwsA(
            isA<DioException>().having(
              (e) => e.error,
              'error',
              isA<HandshakeException>(),
            ),
          ),
        );
      },
    );
  });
}
