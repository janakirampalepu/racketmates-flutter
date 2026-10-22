import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/errors/app_failure.dart';
import 'package:racketmates/common/places/place_models.dart';
import 'package:racketmates/common/places/places_repository.dart';

class WhenWhereState {
  const WhenWhereState({this.loadingCourts = false, this.errors = const []});

  final bool loadingCourts;

  /// Validation errors shown after a failed "Next".
  final List<WhenWhereError> errors;
}

class WhenWhereViewModel extends Notifier<WhenWhereState> {
  @override
  WhenWhereState build() => const WhenWhereState();

  /// A venue was chosen: store it and make sure its courts are known (list
  /// responses may not include them; `GET places/{id}` does).
  Future<void> onPlacePicked(PlaceItem place) async {
    final flow = ref.read(createEventFlowProvider.notifier)..setPlace(place);
    state = const WhenWhereState();
    final id = place.id;
    if (id == null || (place.placeCourts?.isNotEmpty ?? false)) return;
    state = const WhenWhereState(loadingCourts: true);
    try {
      final details = await ref.read(placesRepositoryProvider).details(id);
      if (ref.mounted) flow.setPlaceDetails(details);
    } on AppFailure {
      // Courts are optional; the venue stays selected without them.
    }
    if (ref.mounted) state = const WhenWhereState();
  }

  /// Loads the courts and coordinates of the venue already in the draft (a
  /// rescheduled event starts with the venue's id and name only).
  Future<void> loadPlaceCourts() async {
    final id = ref.read(createEventFlowProvider)?.place?.id;
    if (id == null) return;
    state = const WhenWhereState(loadingCourts: true);
    try {
      final details = await ref.read(placesRepositoryProvider).details(id);
      if (ref.mounted) {
        ref.read(createEventFlowProvider.notifier).setPlaceDetails(details);
      }
    } on AppFailure {
      // Courts are optional; the venue stays as it is.
    }
    if (ref.mounted) state = const WhenWhereState();
  }

  /// True when the step is valid; otherwise exposes the errors.
  bool validate(DateTime now) {
    final draft = ref.read(createEventFlowProvider);
    if (draft == null) return false;
    final errors = validateWhenWhere(draft, now);
    state = WhenWhereState(errors: errors);
    return errors.isEmpty;
  }
}

final whenWhereViewModelProvider =
    NotifierProvider.autoDispose<WhenWhereViewModel, WhenWhereState>(
      WhenWhereViewModel.new,
    );
