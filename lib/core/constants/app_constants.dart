class AppConstants {
  AppConstants._();

  // Hive boxes
  static const String settingsBox = 'settings';
  static const String sessionBox = 'session';

  // Hive keys
  static const String localeKey = 'locale';
  static const String fontSizeKey = 'fontSize';
  static const String themeModeKey = 'themeMode';

  // Firestore collections
  static const String vehiclesCollection = 'vehicles';
  static const String workEntriesCollection = 'workEntries';
  static const String adminEntriesCollection = 'adminEntries';
  static const String messagesCollection = 'messages';
  static const String nativesCollection = 'natives';

  // Firebase Storage paths
  static const String customerPhotosPath = 'customer_photos';
  static const String billPhotosPath = 'bill_photos';

  // Notification channels
  static const String timerChannelId = 'terra_timer';
  static const String timerChannelName = 'Work Timer';
  static const String alertChannelId = 'terra_alerts';
  static const String alertChannelName = 'Alerts';
}
