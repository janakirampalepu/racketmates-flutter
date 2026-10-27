abstract final class ChatChannelDetailsTestIds {
  static const root = 'chat_channel_details_screen';
  static const avatar = 'chat_channel_details_avatar';
  static const title = 'chat_channel_details_title';
  static const muteSwitch = 'chat_channel_details_mute_switch';
  static const memberRow = 'chat_channel_details_member_row';
  static String member(String userId) => '${memberRow}_$userId';
  static const error = 'chat_channel_details_error';
  static const retry = 'chat_channel_details_retry_button';
  static const loading = 'chat_channel_details_loading';
  static const archiveButton = 'chat_channel_details_archive_button';
}
