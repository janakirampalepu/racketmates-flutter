abstract final class HomeTestIds {
  static const root = 'home_screen';
  static const settingsButton = 'home_settings_button';
  static const greeting = 'home_greeting';
  static const list = 'home_list';
  static const maintenanceBanner = 'home_maintenance_banner';
  static const maintenanceBannerDismiss = 'home_maintenance_banner_dismiss';
  static const pendingSection = 'home_pending_actions_section';
  static const upcomingSection = 'home_upcoming_section';
  static const activitySection = 'home_activity_section';
  static const activityYear = 'home_activity_year';
  static const seeAllUpcoming = 'home_see_all_upcoming';
  static const createEvent = 'home_create_event_button';
  static String event(String section, int id) => 'home_${section}_event_$id';
  static String pendingAction(int id) => 'home_pending_action_$id';
  static String retry(String section) => 'home_${section}_retry';
}
