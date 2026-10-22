import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/events/schedule_repository.dart';
import 'package:racketmates/screens/schedule/schedule_view_model.dart';

import '../../support/fakes.dart';

Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  ProviderContainer container(FakeScheduleRepository repo) {
    final c = ProviderContainer(
      overrides: [
        scheduleRepositoryProvider.overrideWithValue(repo),
        selectedUserIdsProvider.overrideWithValue(['7']),
        hourFormatProvider.overrideWithValue(12),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  test(
    'loads page 1, pages on demand, and stops at the first empty page',
    () async {
      final repo = FakeScheduleRepository(
        pages: {
          ScheduleTab.upcoming: [
            [scheduleItem(1), scheduleItem(2)],
            [scheduleItem(3)],
          ],
        },
      );
      final c = container(repo);
      final provider = scheduleListViewModelProvider(ScheduleTab.upcoming);
      final sub = c.listen(provider, (_, _) {});
      addTearDown(sub.close);
      await _settle();
      expect(c.read(provider).items.map((i) => i.eventId), [1, 2]);
      expect(c.read(provider).hasMore, isTrue);

      await c.read(provider.notifier).loadMore();
      expect(c.read(provider).items.map((i) => i.eventId), [1, 2, 3]);

      await c.read(provider.notifier).loadMore(); // page 3 is empty
      expect(c.read(provider).hasMore, isFalse);
      expect(repo.requestedPages, [1, 2, 3]);

      await c.read(provider.notifier).loadMore(); // no further request
      expect(repo.requestedPages, [1, 2, 3]);
    },
  );

  test('an empty first page is an empty state, not an error', () async {
    final c = container(FakeScheduleRepository());
    final provider = scheduleListViewModelProvider(ScheduleTab.past);
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    expect(c.read(provider).isEmpty, isTrue);
    expect(c.read(provider).failure, isNull);
  });

  test('a failed first page can be retried', () async {
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [scheduleItem(1)],
        ],
      },
    )..failing.add('page-upcoming');
    final c = container(repo);
    final provider = scheduleListViewModelProvider(ScheduleTab.upcoming);
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    expect(c.read(provider).failure, isNotNull);
    expect(c.read(provider).items, isEmpty);

    repo.failing.clear();
    await c.read(provider.notifier).retry();
    expect(c.read(provider).failure, isNull);
    expect(c.read(provider).items.single.eventId, 1);
  });

  test('a failed next page keeps the items already loaded', () async {
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [scheduleItem(1)],
          [scheduleItem(2)],
        ],
      },
    );
    final c = container(repo);
    final provider = scheduleListViewModelProvider(ScheduleTab.upcoming);
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    repo.failing.add('page-upcoming');
    await c.read(provider.notifier).loadMore();
    expect(c.read(provider).items, hasLength(1));
    expect(c.read(provider).failure, isNotNull);
    expect(c.read(provider).hasMore, isTrue);
  });

  test('refresh restarts from page 1', () async {
    final repo = FakeScheduleRepository(
      pages: {
        ScheduleTab.upcoming: [
          [scheduleItem(1)],
          [scheduleItem(2)],
        ],
      },
    );
    final c = container(repo);
    final provider = scheduleListViewModelProvider(ScheduleTab.upcoming);
    final sub = c.listen(provider, (_, _) {});
    addTearDown(sub.close);
    await _settle();
    await c.read(provider.notifier).loadMore();
    await c.read(provider.notifier).refresh();
    expect(c.read(provider).items.map((i) => i.eventId), [1]);
    expect(repo.requestedPages.last, 1);
  });
}
