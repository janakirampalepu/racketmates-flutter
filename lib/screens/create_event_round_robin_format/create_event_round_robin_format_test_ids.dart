abstract final class CreateEventRoundRobinFormatTestIds {
  static const root = 'create_event_rr_format_screen';
  static const title = 'create_event_rr_format_title';
  static const next = 'create_event_rr_format_next_button';

  /// `create_event_rr_format_<est_classic|est_king_of_the_court|est_manual>`.
  static String format(String key) => 'create_event_rr_format_$key';
}
