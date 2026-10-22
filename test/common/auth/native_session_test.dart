import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/native_session.dart';

import '../../support/fakes.dart';

const _android =
    '{"access_token":"a1","token_type":"Bearer","expires_in":7200,'
    '"refresh_token":"r1","created_at":1700000000,'
    '"user":{"id":7,"uid":"u-7","uuid":"id-7","is_signed_up":true}}';

// The iOS app stores `SessionResponse`: no token_type or created_at, and
// expires_in as a decimal.
const _ios =
    '{"access_token":"a2","expires_in":7200.0,"refresh_token":"r2",'
    '"user":{"id":8,"uid":"u-8","first_name":"Alex"}}';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('parseNativeSession', () {
    test('Android: the OAuth response as stored', () {
      final t = parseNativeSession(_android, platform: TargetPlatform.android)!;
      expect(t.accessToken, 'a1');
      expect(t.refreshToken, 'r1');
      expect(t.tokenType, 'Bearer');
      expect(t.expiresIn, 7200);
      expect(t.createdAt, 1700000000);
      expect(t.user?.id, 7);
      expect(t.user?.uid, 'u-7');
      expect(t.user?.uuid, 'id-7');
      expect(t.user?.isSignedUp, isTrue);
    });

    test('iOS: decimal expires_in, no created_at, default token type', () {
      final t = parseNativeSession(_ios, platform: TargetPlatform.iOS)!;
      expect(t.accessToken, 'a2');
      expect(t.expiresIn, 7200);
      expect(t.createdAt, isNull);
      expect(t.tokenType, 'Bearer');
      expect(t.user?.id, 8);
      expect(t.user?.isSignedUp, isNull); // iOS treats missing as signed up
      // Without created_at it is not known to be expired: the first 401
      // refreshes it.
      expect(t.isExpiredAt(DateTime(2100)), isFalse);
    });

    test('a refresh token is required (it could not be renewed otherwise)', () {
      expect(
        parseNativeSession(
          '{"access_token":"a","user":{"id":1}}',
          platform: TargetPlatform.android,
        ),
        isNull,
      );
      expect(
        parseNativeSession(
          '{"refresh_token":"r"}',
          platform: TargetPlatform.android,
        ),
        isNull,
      );
    });

    test('an unfinished sign-up is not carried over', () {
      expect(
        parseNativeSession(
          '{"access_token":"a","refresh_token":"r","user":{"id":1,"is_signed_up":false}}',
          platform: TargetPlatform.android,
        ),
        isNull,
      );
    });

    test('empty, malformed and non-object values', () {
      for (final raw in [null, '', '   ', 'not json', '[1,2]', '"x"', '{']) {
        expect(
          parseNativeSession(raw, platform: TargetPlatform.android),
          isNull,
          reason: '$raw',
        );
      }
    });

    test('a session without a user is still usable', () {
      final t = parseNativeSession(
        '{"access_token":"a","refresh_token":"r"}',
        platform: TargetPlatform.android,
      );
      expect(t?.user, isNull);
    });
  });

  group('NativeSessionImporter', () {
    test('reads, parses and removes the native copy', () async {
      final source = FakeNativeSessionSource(_android);
      final t = await NativeSessionImporter(source)
          .import(platform: TargetPlatform.android);
      expect(t?.refreshToken, 'r1');
      expect(source.clears, 1);
    });

    test('an unusable copy is removed too', () async {
      final source = FakeNativeSessionSource('garbage');
      final t = await NativeSessionImporter(source)
          .import(platform: TargetPlatform.android);
      expect(t, isNull);
      expect(source.clears, 1);
    });

    test('nothing stored: nothing removed', () async {
      final source = FakeNativeSessionSource();
      expect(
        await NativeSessionImporter(source)
            .import(platform: TargetPlatform.iOS),
        isNull,
      );
      expect(source.clears, 0);
    });
  });

  group('MethodChannelNativeSessionSource', () {
    const channel = MethodChannelNativeSessionSource.channel;
    final calls = <String>[];

    void mock(Future<Object?> Function(MethodCall call) handler) {
      TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            calls.add(call.method);
            return handler(call);
          });
    }

    setUp(calls.clear);
    tearDown(
      () => TestWidgetsFlutterBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );

    test('read and clear go to the platform', () async {
      mock((call) async => call.method == 'read' ? _android : null);
      const source = MethodChannelNativeSessionSource();
      expect(await source.read(), _android);
      await source.clear();
      expect(calls, ['read', 'clear']);
    });

    test('a platform error means no session', () async {
      mock((call) async => throw PlatformException(code: 'keystore'));
      const source = MethodChannelNativeSessionSource();
      expect(await source.read(), isNull);
      await source.clear(); // does not throw
    });

    test('no platform code means no session', () async {
      mock((call) async => throw MissingPluginException());
      const source = MethodChannelNativeSessionSource();
      expect(await source.read(), isNull);
      await source.clear();
    });
  });
}
