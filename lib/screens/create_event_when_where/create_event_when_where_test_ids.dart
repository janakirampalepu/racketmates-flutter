abstract final class CreateEventWhenWhereTestIds {
  static const root = 'create_event_when_where_screen';
  static const title = 'create_event_when_where_title';
  static const next = 'create_event_when_where_next_button';
  static const venueButton = 'create_event_venue_button';
  static const venueError = 'create_event_venue_error';
  static const courtCountPrefix = 'create_event_court_count';
  static const courtsLoading = 'create_event_courts_loading';
  static const noCourts = 'create_event_no_courts';
  static const dateButton = 'create_event_date_button';
  static const timeButton = 'create_event_time_button';
  static const startError = 'create_event_start_error';
  static const duration = 'create_event_duration_field';
  static const notes = 'create_event_notes_field';
  static String court(int id) => 'create_event_court_$id';
}
