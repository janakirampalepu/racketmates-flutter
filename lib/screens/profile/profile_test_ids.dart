abstract final class ProfileTestIds {
  static const root = 'profile_screen';
  static const title = 'profile_title';
  static const avatar = 'profile_avatar';
  static const changePhoto = 'profile_change_photo_button';
  static const removePhoto = 'profile_remove_photo_button';
  static const takePhoto = 'profile_take_photo_option';
  static const choosePhoto = 'profile_choose_photo_option';
  static const photoFailed = 'profile_photo_failed';
  static const firstName = 'profile_first_name_field';
  static const lastName = 'profile_last_name_field';
  static const email = 'profile_email_field';
  static const phone = 'profile_phone';
  static const changePhone = 'profile_change_phone_button';
  static const firstNameError = 'profile_first_name_error';
  static const lastNameError = 'profile_last_name_error';
  static const emailError = 'profile_email_error';
  static const save = 'profile_save_button';
  static const saveFailed = 'profile_save_failed';
  static const loadError = 'profile_load_error';
  static const retry = 'profile_retry_button';
}

abstract final class ShareTestIds {
  static const root = 'share_screen';
  static const title = 'share_title';
  static const share = 'share_share_button';
  static const copy = 'share_copy_button';
}

abstract final class ContactTestIds {
  static const root = 'contact_screen';
  static const title = 'contact_title';
  static const email = 'contact_email_field';
  static const subject = 'contact_subject_field';
  static const question = 'contact_question_field';
  static const emailError = 'contact_email_error';
  static const subjectError = 'contact_subject_error';
  static const questionError = 'contact_question_error';
  static const submit = 'contact_submit_button';
  static const failed = 'contact_failed';
}

abstract final class DeleteAccountTestIds {
  static const root = 'delete_account_screen';
  static const title = 'delete_account_title';
  static const subscriptionNote = 'delete_account_subscription_note';
  static const manageSubscription = 'delete_account_manage_subscription';
  static const delete = 'delete_account_button';
  static const confirmDelete = 'delete_account_confirm_button';
  static const cancel = 'delete_account_cancel_button';
  static const processing = 'delete_account_processing_dialog';
  static const processingOk = 'delete_account_processing_ok';
  static const failed = 'delete_account_failed';
}

abstract final class RolesTestIds {
  static const root = 'roles_screen';
  static const title = 'roles_title';
  static const player = 'roles_player_tile';
  static const coach = 'roles_coach_tile';
  static const parent = 'roles_parent_tile';
  static const loadError = 'roles_load_error';
  static const retry = 'roles_retry_button';

  static const sportsRoot = 'role_sports_screen';
  static const sportsTitle = 'role_sports_title';
  static const sportsSave = 'role_sports_save_button';
  static const sportsError = 'role_sports_error';
  static const sportsFailed = 'role_sports_failed';

  /// `role_sport_<st_*>`.
  static String sport(String key) => 'role_sport_$key';
}

abstract final class KidsSettingsTestIds {
  static const root = 'kids_settings_screen';
  static const title = 'kids_settings_title';
  static const enable = 'kids_settings_enable';
  static const add = 'kids_settings_add_button';
  static const max = 'kids_settings_max';
  static const removeFailed = 'kids_settings_remove_failed';
  static const confirmYes = 'kids_settings_confirm_yes_button';
  static const confirmNo = 'kids_settings_confirm_no_button';

  /// `kid_<id>`, `kid_<id>_edit`, `kid_<id>_remove`.
  static String kid(int id) => 'kid_$id';
  static String edit(int id) => 'kid_${id}_edit';
  static String remove(int id) => 'kid_${id}_remove';
}

abstract final class KidEditTestIds {
  static const root = 'kid_edit_screen';
  static const title = 'kid_edit_title';
  static const firstName = 'kid_edit_first_name_field';
  static const lastName = 'kid_edit_last_name_field';
  static const mobile = 'kid_edit_mobile_field';
  static const firstNameError = 'kid_edit_first_name_error';
  static const lastNameError = 'kid_edit_last_name_error';
  static const mobileError = 'kid_edit_mobile_error';
  static const sportError = 'kid_edit_sport_error';
  static const save = 'kid_edit_save_button';
  static const failed = 'kid_edit_failed';

  /// `kid_edit_sport_<st_*>`.
  static String sport(String key) => 'kid_edit_sport_$key';
}

abstract final class ChangePhoneTestIds {
  static const root = 'change_phone_screen';
  static const title = 'change_phone_title';
  static const country = 'change_phone_country_button';
  static const number = 'change_phone_number_field';
  static const send = 'change_phone_send_button';
  static const code = 'change_phone_code_field';
  static const verify = 'change_phone_verify_button';
  static const resend = 'change_phone_resend_button';
  static const error = 'change_phone_error';
}
