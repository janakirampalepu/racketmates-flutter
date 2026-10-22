abstract final class CreateEventAssignPlayersTestIds {
  static const root = 'create_event_assign_players_screen';
  static const title = 'create_event_assign_players_title';
  static const next = 'create_event_assign_players_next_button';
  static const error = 'create_event_assign_players_error';

  /// `create_event_slot_<match>_<ecs_top|ecs_bottom>_<epp_*>` (match 0-based).
  static String slot(int match, String side, String position) =>
      'create_event_slot_${match}_${side}_$position';

  static String clear(int match, String side, String position) =>
      '${slot(match, side, position)}_clear';
}
