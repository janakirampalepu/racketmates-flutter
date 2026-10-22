abstract final class KidsListTestIds {
  static const root = 'kids_list_screen';
  static const title = 'kids_list_title';
  static const add = 'kids_list_add_button';
  static const next = 'kids_list_next_button';
  static const error = 'kids_list_error';
  static String kid(int index) => 'kids_list_item_$index';
  static String edit(int index) => 'kids_list_edit_$index';
  static String remove(int index) => 'kids_list_remove_$index';
}
