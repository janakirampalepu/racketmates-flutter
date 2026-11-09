import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/schedule_filter.dart';
import 'package:racketmates/common/sign_up/sign_up_draft.dart';

import '../../support/fakes.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('ScheduleFilter', () {
    test('eventRoles is sorted; sportTypesOrNull is null when empty', () {
      const filter = ScheduleFilter(
        ownerships: {ownershipParticipant, ownershipManaging},
        sportTypes: {},
      );
      expect(filter.eventRoles, ['managing', 'participant']);
      expect(filter.sportTypesOrNull, isNull);
    });

    test('sportTypesOrNull is a sorted list when not empty', () {
      const filter = ScheduleFilter(sportTypes: {'st_tennis', 'st_badminton'});
      expect(filter.sportTypesOrNull, ['st_badminton', 'st_tennis']);
    });
  });

  group('ScheduleFilterNotifier', () {
    ProviderContainer container({
      required Set<SportKey> sports,
      InMemoryScheduleFilterStore? store,
    }) {
      final c = ProviderContainer(
        overrides: [
          accountSportsProvider.overrideWith((ref) async => sports),
          scheduleFilterStoreProvider(false)
              .overrideWithValue(store ?? InMemoryScheduleFilterStore()),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test(
      'with one sport, no stored filter: no sport filter is applied',
      () async {
        final c = container(sports: {SportKey.tennis});
        final sub = c.listen(scheduleFilterProvider(false), (_, _) {});
        addTearDown(sub.close);
        await _settle();
        expect(c.read(scheduleFilterProvider(false)).sportTypes, isEmpty);
      },
    );

    test(
      'with several sports, no stored filter: every sport defaults selected',
      () async {
        final c = container(sports: {SportKey.tennis, SportKey.padel});
        final sub = c.listen(scheduleFilterProvider(false), (_, _) {});
        addTearDown(sub.close);
        await _settle();
        expect(c.read(scheduleFilterProvider(false)).sportTypes, {
          'st_tennis',
          'st_padel',
        });
      },
    );

    test('a stored filter wins over the computed default', () async {
      final store = InMemoryScheduleFilterStore()
        ..value = const ScheduleFilter(
          ownerships: {ownershipManaging},
          sportTypes: {'st_badminton'},
        );
      final c = container(
        sports: {SportKey.tennis, SportKey.padel},
        store: store,
      );
      final sub = c.listen(scheduleFilterProvider(false), (_, _) {});
      addTearDown(sub.close);
      await _settle();
      final filter = c.read(scheduleFilterProvider(false));
      expect(filter.ownerships, {ownershipManaging});
      expect(filter.sportTypes, {'st_badminton'});
    });

    test('ownerships never ends up empty', () async {
      final c = container(sports: {});
      final sub = c.listen(scheduleFilterProvider(false), (_, _) {});
      addTearDown(sub.close);
      await _settle();
      final notifier = c.read(scheduleFilterProvider(false).notifier);
      notifier.setOwnerships({});
      expect(c.read(scheduleFilterProvider(false)).ownerships, {
        ownershipManaging,
        ownershipParticipant,
      });
    });

    test('a selection change is persisted to the store', () async {
      final store = InMemoryScheduleFilterStore();
      final c = container(sports: {SportKey.tennis}, store: store);
      final sub = c.listen(scheduleFilterProvider(false), (_, _) {});
      addTearDown(sub.close);
      await _settle();
      c.read(scheduleFilterProvider(false).notifier).setOwnerships({
        ownershipManaging,
      });
      await _settle();
      expect(store.value?.ownerships, {ownershipManaging});
    });
  });
}
