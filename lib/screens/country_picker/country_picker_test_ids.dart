abstract final class CountryPickerTestIds {
  static const root = 'country_picker_screen';
  static const search = 'country_picker_search';
  static const list = 'country_picker_list';

  /// One row per country: `country_picker_item_<REGION>`.
  static String item(String regionCode) => 'country_picker_item_$regionCode';
}
