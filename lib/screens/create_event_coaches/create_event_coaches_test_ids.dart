import 'package:racketmates/common/widgets/people_step.dart';

abstract final class CreateEventCoachesTestIds {
  static const ids = PeopleStepIds('create_event_coaches');
  static final root = ids.root;
  static final next = ids.next;
  static final error = ids.error;
  static final search = ids.search;

  /// `create_event_coaches_person_<id>`.
  static String coach(int id) => ids.person(id);
}
