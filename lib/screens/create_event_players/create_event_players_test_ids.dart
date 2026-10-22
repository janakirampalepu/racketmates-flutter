import 'package:racketmates/common/widgets/people_step.dart';

abstract final class CreateEventPlayersTestIds {
  static const ids = PeopleStepIds('create_event_players');
  static final root = ids.root;
  static final title = ids.title;
  static final search = ids.search;
  static final next = ids.next;
  static final error = ids.error;
  static final empty = ids.empty;
  static final retry = ids.retry;
  static final selected = ids.selected;

  /// Kept from the first wizard version: `create_event_player_<id>`.
  static String player(int id) => 'create_event_players_person_$id';
}
