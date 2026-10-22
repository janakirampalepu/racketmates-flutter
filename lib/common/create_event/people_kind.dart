import 'package:racketmates/common/create_event/create_event_flow.dart';
import 'package:racketmates/common/create_event/event_draft.dart';
import 'package:racketmates/common/users/models/app_user.dart';

/// The two "pick people" steps of the wizard.
enum PeopleKind {
  coaches,
  players;

  /// `roles[]` filter of the user search: coaches are `ur_coach`, players
  /// `ur_player`; meetup attendees can hold any role.
  String? roleFor(EventDraft draft) => switch (this) {
    PeopleKind.coaches => RoleKeys.coach,
    PeopleKind.players =>
      draft.spec?.participantsAreAudience ?? false ? null : RoleKeys.player,
  };

  /// `sport_types[]` filter (none for sport-less meetups).
  String? sportFor(EventDraft draft) =>
      (draft.spec?.needsSport ?? true) ? draft.sport?.key : null;

  List<AppUser> selected(EventDraft draft) => switch (this) {
    PeopleKind.coaches => draft.coaches,
    PeopleKind.players => draft.invitees,
  };

  void toggle(CreateEventFlow flow, AppUser user) => switch (this) {
    PeopleKind.coaches => flow.toggleCoach(user),
    PeopleKind.players => flow.toggleInvitee(user),
  };
}
