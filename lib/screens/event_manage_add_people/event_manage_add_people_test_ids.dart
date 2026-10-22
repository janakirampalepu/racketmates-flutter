abstract final class EventManageAddPeopleTestIds {
  static const root = 'event_manage_add_people_screen';
  static const title = 'event_manage_add_people_title';
  static const search = 'event_manage_add_people_search';
  static const add = 'event_manage_add_people_button';
  static const empty = 'event_manage_add_people_empty';
  static const retry = 'event_manage_add_people_retry';
  static const error = 'event_manage_add_people_error';

  /// `event_manage_add_person_<userId>`.
  static String person(int id) => 'event_manage_add_person_$id';
}
