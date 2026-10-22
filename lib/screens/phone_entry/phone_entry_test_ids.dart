/// Identifiers reuse the native iOS values where they exist
/// (`SignInView` / `NumberValidationSheet`).
abstract final class PhoneEntryTestIds {
  static const root = 'phone_entry_screen';
  static const title = 'signUp_mobile_number_title';
  static const description = 'signUp_mobile_number_field_description';
  static const countryButton = 'signUp_country_button';
  static const numberField = 'signUp_mobile_number_field_text';
  static const errorText = 'signUp_mobile_number_error';
  static const continueButton = 'signUp_continue_button';
  static const backButton = 'signUp_back_button';

  // Mode mismatch dialog (iOS `PhoneNumberValidationSheet`).
  static const dialogTitle = 'phone_number_validation_header_title_label';
  static const dialogMessage =
      'phone_number_validation_header_description_label';
  static const dialogContinue = 'phone_number_validation_continue_button';
  static const dialogClose = 'phone_number_validation_close_button';
}
