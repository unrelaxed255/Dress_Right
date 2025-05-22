// lib/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  // Singleton pattern
  NotificationService._();
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone database
    tz.initializeTimeZones();
    // Set default location - you might want to make this dynamic
    tz.setLocalLocation(tz.getLocation('America/New_York'));

    // Plugin initialization settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    final ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    await _plugin.initialize(
      InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Request permissions explicitly for iOS
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Android permissions (Android 13+)
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    // Request iOS permissions
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    await iosPlugin?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Handle notification tap
  void _onDidReceiveNotificationResponse(NotificationResponse response) async {
    // Handle notification tap here
    print('Notification tapped: ${response.payload}');
    // You can navigate to specific screens based on the payload
  }

  Future<bool> scheduleInspectionReminder({
    required int id,
    required String title,
    required String body,
    required DateTime when,
  }) async {
    try {
      final scheduledDate = tz.TZDateTime.from(when, tz.local);
      
      // Check if the scheduled time is in the future
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
        print('Cannot schedule notification in the past');
        return false;
      }
      
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'srr_channel',
            'SRR Reminders',
            channelDescription: 'Self-Reporting Requirement inspection reminders',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
            styleInformation: const BigTextStyleInformation(''),
            ticker: 'SRR Inspection Reminder',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            sound: 'default.wav',
            badgeNumber: 1,
            subtitle: 'DressRight App',
            threadIdentifier: 'srr_reminders',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'srr_reminder_$id', // For handling taps
      );
      
      return true;
    } catch (e) {
      print('Error scheduling notification: $e');
      return false;
    }
  }
  
  // Cancel a specific notification by ID
  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
  }
  
  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
  
  // Get all pending notification requests
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _plugin.pendingNotificationRequests();
  }

  // Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      return await androidPlugin.areNotificationsEnabled() ?? false;
    } else if (iosPlugin != null) {
      final settings = await iosPlugin.checkPermissions();
      return settings?.isEnabled ?? false;
    }
    
    return false;
  }

  // Show immediate notification (for testing)
  Future<void> showImmediateNotification({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      0,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'test_channel',
          'Test Notifications',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}