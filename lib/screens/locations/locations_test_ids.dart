abstract final class LocationsTestIds {
  static const root = 'locations_screen';
  static const title = 'locations_title';
  static const search = 'locations_search_field';
  static const tabNearby = 'locations_tab_nearby';
  static const tabFavourites = 'locations_tab_favourites';
  static const list = 'locations_list';
  static const empty = 'locations_empty';
  static const error = 'locations_error';
  static const retry = 'locations_retry_button';
  static const locationBanner = 'locations_location_banner';
  static const enableLocation = 'locations_enable_location_button';
  static const openSettings = 'locations_open_settings_button';
  static const filterButton = 'locations_filter_button';
  static const filterSheet = 'locations_filter_sheet';
  static const distanceSlider = 'locations_distance_slider';
  static const filterApply = 'locations_filter_apply_button';
  static const filterReset = 'locations_filter_reset_button';

  /// `locations_place_<id>`.
  static String place(int id) => 'locations_place_$id';

  /// `locations_favourite_<id>`.
  static String favourite(int id) => 'locations_favourite_$id';
}

abstract final class VenueTestIds {
  static const root = 'venue_screen';
  static const title = 'venue_title';
  static const address = 'venue_address';
  static const distance = 'venue_distance';
  static const type = 'venue_type';
  static const membership = 'venue_membership';
  static const courts = 'venue_courts';
  static const noCourts = 'venue_no_courts';
  static const directions = 'venue_directions_button';
  static const favourite = 'venue_favourite_button';
  static const loading = 'venue_loading';
  static const error = 'venue_error';
  static const retry = 'venue_retry_button';

  /// `venue_court_<id>`.
  static String court(int id) => 'venue_court_$id';
}
