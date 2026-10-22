abstract final class CreateEventReviewTestIds {
  static const root = 'create_event_review_screen';
  static const title = 'create_event_review_title';
  static const create = 'create_event_create_button';
  static const error = 'create_event_error';
  static const summaryType = 'create_event_review_type';
  static const summarySport = 'create_event_review_sport';
  static const summaryWhen = 'create_event_review_when';
  static const summaryWhere = 'create_event_review_where';
  static const summaryCoaches = 'create_event_review_coaches';
  static const summaryInvited = 'create_event_review_invited';
  static const summaryScoring = 'create_event_review_scoring';

  /// `create_event_summary_match_<index>` (0-based).
  static String summaryMatch(int index) => 'create_event_review_match_$index';
}
