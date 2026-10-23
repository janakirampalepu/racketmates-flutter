import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/auth/auth_providers.dart';
import 'package:racketmates/common/config/config_providers.dart';
import 'package:racketmates/common/events/participant_status_filter.dart';

import '../../support/fakes.dart';

Future<String?> _key(Object? answer) async {
  final container = ProviderContainer(
    overrides: [
      environmentConfigProvider.overrideWithValue(testConfig),
      authApiProvider.overrideWithValue(
        FakeAuthApi()..statusFilterOptions = answer,
      ),
    ],
  );
  addTearDown(container.dispose);
  return container.read(participantStatusFilterKeyProvider.future);
}

void main() {
  test('the first filter option is used', () async {
    expect(
      await _key({
        'filter_options': [
          {'key': 'eus_confirmed', 'label': 'Confirmed'},
          {'key': 'eus_invited', 'label': 'Invited'},
        ],
      }),
      'eus_confirmed',
    );
  });

  test('no options, odd answers or a failed call mean no filter', () async {
    expect(await _key({'filter_options': <Object>[]}), isNull);
    expect(
      await _key({
        'filter_options': [<String, Object>{}],
      }),
      isNull,
    );
    expect(await _key('nope'), isNull);
    expect(await _key(null), isNull); // the fake fails
  });
}
