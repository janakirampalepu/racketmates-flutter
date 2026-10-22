import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/events/event_actions_api.dart';
import 'package:racketmates/common/events/event_actions_repository.dart';

import '../../support/fixtures.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status, this.body);

  final int status;
  final Object body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

EventActionsRepositoryImpl _repo(_Adapter adapter) =>
    EventActionsRepositoryImpl(
      EventActionsApi(
        Dio(BaseOptions(baseUrl: 'https://api.example.test'))
          ..httpClientAdapter = adapter,
      ),
    );

void main() {
  const base = 'events/101/event_participants/1';

  test('accept: POST accept_invite with event_schedule_option_ids', () async {
    final adapter = _Adapter(200, apiFixture('events_show_accepted'));
    final response = await _repo(adapter).accept(101, 1);
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '$base/accept_invite');
    expect(adapter.last!.data, {'event_schedule_option_ids': <int>[]});
    expect(response.event!.id, 101);
  });

  test('decline: POST decline_invite with empty option ids', () async {
    final adapter = _Adapter(200, apiFixture('events_show_declined'));
    await _repo(adapter).decline(101, 1);
    expect(adapter.last!.path, '$base/decline_invite');
    expect(adapter.last!.data, {'event_schedule_option_ids': <int>[]});
  });

  test('rejoin: POST rejoin_event with the previously selected ids', () async {
    final adapter = _Adapter(200, apiFixture('events_show_accepted'));
    await _repo(adapter).rejoin(101, 1, scheduleOptionIds: [900]);
    expect(adapter.last!.path, '$base/rejoin_event');
    expect(adapter.last!.data, {
      'event_schedule_option_ids': [900],
    });
  });

  test('leave: POST leave_event without a body', () async {
    final adapter = _Adapter(200, apiFixture('events_show_declined'));
    await _repo(adapter).leave(101, 1);
    expect(adapter.last!.method, 'POST');
    expect(adapter.last!.path, '$base/leave_event');
    expect(adapter.last!.data, isNull);
  });

  test('join waitlist: POST join_waitlist with an empty request', () async {
    final adapter = _Adapter(200, apiFixture('events_show_accepted'));
    await _repo(adapter).joinWaitlist(101, 1);
    expect(adapter.last!.path, '$base/join_waitlist');
    expect(adapter.last!.data, <String, dynamic>{});
  });

  test('cancel event: PUT cancel_event with reason and remove_event', () async {
    final adapter = _Adapter(200, <String, dynamic>{});
    await _repo(adapter)
        .cancelEvent(101, reason: '  Rain  ', removeEvent: true);
    expect(adapter.last!.method, 'PUT');
    expect(adapter.last!.path, 'events/101/cancel_event');
    expect(adapter.last!.data, {
      'cancellation_reason': 'Rain',
      'remove_event': true,
    });

    await _repo(adapter).cancelEvent(101, reason: '  ');
    expect(adapter.last!.data, {'remove_event': false});
  });

  test('HTTP 422 carries the server message', () async {
    final adapter = _Adapter(422, {
      'message': 'This event is full',
      'result': 'error',
    });
    await expectLater(
      _repo(adapter).accept(101, 1),
      throwsA(
        isA<ServerFailure>()
            .having((f) => f.statusCode, 'status', 422)
            .having((f) => f.message, 'message', 'This event is full'),
      ),
    );
  });
}
