import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

// flutter_local_notifications has no Web implementation, so every method
// here is a no-op when running on Web (kIsWeb) to avoid a MissingPluginException
// at startup. Local "timer running" / "entry saved" notifications are a
// mobile-only nice-to-have; the rest of the app works the same on Web.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    if (kIsWeb) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    // Create Android channels
    const timerChannel = AndroidNotificationChannel(
      AppConstants.timerChannelId,
      AppConstants.timerChannelName,
      importance: Importance.low,
      showBadge: false,
    );
    const alertChannel = AndroidNotificationChannel(
      AppConstants.alertChannelId,
      AppConstants.alertChannelName,
      importance: Importance.high,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(timerChannel);
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alertChannel);
  }

  Future<void> showTimerNotification({
    required String customerName,
    required String elapsed,
  }) async {
    if (kIsWeb) return;
    await _plugin.show(
      1,
      'TerraTrack — Timer Running',
      '$customerName · $elapsed elapsed',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.timerChannelId,
          AppConstants.timerChannelName,
          ongoing: true,
          autoCancel: false,
          priority: Priority.low,
          importance: Importance.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
        ),
      ),
    );
  }

  Future<void> cancelTimerNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(1);
  }

  Future<void> showEntrySavedNotification(String customerName) async {
    if (kIsWeb) return;
    await _plugin.show(
      2,
      'Entry Saved',
      'Work entry for $customerName saved successfully',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alertChannelId,
          AppConstants.alertChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> showAdminMessageNotification(String message) async {
    if (kIsWeb) return;
    await _plugin.show(
      3,
      'Message from Admin',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.alertChannelId,
          AppConstants.alertChannelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
