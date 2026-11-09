/// Native (iOS) identifiers, from `ProfileSettingsView`'s own
/// `AccessibilityIdentifiers` struct and its `navigationRowView`/
/// `roleRowView` helpers' per-row id patterns
/// (`profile_settings_row_<imageName>`, `profile_settings_row_title_<text>`,
/// `profile_settings_<title>_arrow_icon`/`_external_link_icon`). Reused
/// verbatim per CLAUDE.md §9.1 rather than inventing a parallel scheme; a
/// Flutter-only row (no native counterpart here) keeps a `settings_*` id,
/// noted below. Dynamic, localized-text-embedded native ids
/// (`profile_settings_row_title_<text>`, `profile_settings_<title>_arrow_icon`
/// /`_external_link_icon`, `profile_settings_section_title_<title>`) are not
/// ported — CLAUDE.md §9.1 itself requires identifiers that are *not*
/// localized text, so faithfully reproducing these would both contradict
/// that rule and be brittle across languages; left as a documented gap.
abstract final class SettingsTestIds {
  static const root = 'settings_screen';
  // Flutter-only: native has no screen-root identifier.
  static const title = 'settings_title';
  static const help = 'profile_settings_support_icon';
  static const name = 'profile_settings_user_name';
  static const email = 'profile_settings_user_email';
  static const avatar = 'profile_settings_user_avatar';
  static const version = 'profile_settings_user_version';
  static const subscriptionTile = 'profile_settings_row_subscription_icon';
  static const myNumber = 'profile_settings_row_mobile_icon';
  static const phoneNumber = 'profile_settings_phone_number';
  static const locations = 'profile_settings_row_Location';
  static const profile = 'profile_settings_edit_icon';
  static const share = 'profile_settings_row_share_icon';
  static const contact = 'profile_settings_row_support_icon';
  static const deleteAccount = 'profile_Settings_delete_icon';
  static const deleteButtonText = 'profile_settings_delete_button_text';
  static const notifications = 'profile_settings_row_notification_icon';
  static const reminders = 'profile_settings_row_Calendar';
  static const rate = 'profile_settings_row_review_icon';
  static const support = 'profile_settings_row_support_icon';
  static const logout = 'profile_settings_logout_icon';
  static const logoutButtonText = 'profile_Settings_logout_button_text';
  static const addButton = 'profile_settings_add_button';
  static const subscriptionPremiumIcon =
      'profile_settings_subscription_premium_icon';
  static const subscriptionFreeIcon = 'profile_settings_subscription_free_icon';
  static const subscriptionPremiumLabel =
      'profile_settings_subscription_premium_label';
  static const subscriptionFreeLabel =
      'profile_settings_subscription_free_label';
  // Flutter-only: the confirm/cancel buttons are an `AlertDialog`, not
  // native's own `Alert` (which has no identifiers on these two buttons).
  static const logoutConfirm = 'settings_logout_confirm_button';
  static const logoutCancel = 'settings_logout_cancel_button';
}
