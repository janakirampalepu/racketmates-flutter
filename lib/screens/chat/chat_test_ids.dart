abstract final class ChatTestIds {
  static const root = 'chat_screen';
  static const title = 'chat_title';
  static const connecting = 'chat_connecting';
  static const unavailable = 'chat_unavailable';
  static const failed = 'chat_failed';
  static const retry = 'chat_retry_button';
  static const list = 'chat_channel_list';
  static const newChatButton = 'chat_new_chat_button';
  static const channelRoot = 'chat_channel_screen';
  static const channelBackButton = 'chat_channel_back_button';
  static const channelHeader = 'chat_channel_header';
  static const channelAvatar = 'chat_channel_avatar';
  static const channelTitle = 'chat_channel_title';
  static const tabActive = 'chat_tab_active';
  static const tabArchived = 'chat_tab_archived';
  static const empty = 'chat_empty';
  static const listError = 'chat_list_error';
  static const listRetry = 'chat_list_retry';
  static const listLoading = 'chat_list_loading';

  /// `chat_row_<channelUrl>` (URLs aren't valid bare identifiers, but this
  /// app's `TestId`/Appium convention doesn't require that).
  static String row(String channelUrl) => 'chat_row_$channelUrl';
}
