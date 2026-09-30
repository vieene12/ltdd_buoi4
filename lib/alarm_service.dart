import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AlarmService {
  AlarmService._();

  static final AlarmService instance = AlarmService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const MethodChannel _systemAlarmChannel = MethodChannel(
    'com.example.buoi4/system_alarm',
  );
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final timeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZone.identifier));
    } catch (_) {
      // Dự phòng phù hợp với ứng dụng tiếng Việt nếu nền tảng không trả múi giờ.
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    }

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('ic_notification'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    await _notifications.initialize(settings: settings);
    _initialized = true;
  }

  Future<void> schedule(DateTime dateTime) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _systemAlarmChannel.invokeMethod<bool>(
        'setSystemAlarm',
        <String, Object>{
          'hour': dateTime.hour,
          'minute': dateTime.minute,
          'message': 'Báo thức từ ứng dụng buoi4',
        },
      );
      return;
    }

    await initialize();
    await _requestPermissions();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'alarm_channel_v1',
        'Báo thức',
        channelDescription: 'Thông báo báo thức đã đặt',
        category: AndroidNotificationCategory.alarm,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );

    final scheduledDate = tz.TZDateTime.from(dateTime, tz.local);
    await _notifications.zonedSchedule(
      id: dateTime.millisecondsSinceEpoch.remainder(2147483647),
      title: 'Đến giờ rồi!',
      body:
          'Báo thức ${_twoDigits(dateTime.hour)}:${_twoDigits(dateTime.minute)}',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final notificationsAllowed = await android
          ?.requestNotificationsPermission();
      if (notificationsAllowed == false) {
        throw StateError('Bạn chưa cấp quyền hiển thị thông báo.');
      }
      final exactAlarmsAllowed = await android?.requestExactAlarmsPermission();
      if (exactAlarmsAllowed == false) {
        throw StateError('Bạn chưa cấp quyền đặt báo thức chính xác.');
      }
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final allowed = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      if (allowed == false) {
        throw StateError('Bạn chưa cấp quyền hiển thị thông báo.');
      }
    }
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');
}
