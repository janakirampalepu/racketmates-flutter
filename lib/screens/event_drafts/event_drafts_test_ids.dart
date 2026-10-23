abstract final class EventDraftsTestIds {
  static const root = 'event_drafts_screen';
  static const title = 'event_drafts_title';
  static const empty = 'event_drafts_empty';
  static const error = 'event_drafts_error';
  static const retry = 'event_drafts_retry_button';
  static const confirmYes = 'event_drafts_confirm_yes_button';
  static const confirmNo = 'event_drafts_confirm_no_button';
  static const openFailed = 'event_drafts_open_failed';
  static const opening = 'event_drafts_opening';

  /// `event_draft_<eventId>`, `event_draft_<eventId>_delete`.
  static String draft(int id) => 'event_draft_$id';
  static String delete(int id) => 'event_draft_${id}_delete';
}

abstract final class EventDraftActionIds {
  static const menu = 'create_event_draft_menu';
  static const save = 'create_event_draft_save';
  static const discard = 'create_event_draft_discard';
  static const discardConfirm = 'create_event_draft_discard_confirm';
  static const discardKeep = 'create_event_draft_discard_keep';
  static const saving = 'create_event_draft_saving';
  static const scheduleButton = 'schedule_drafts_button';
}
