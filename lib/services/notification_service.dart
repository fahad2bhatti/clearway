import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../core/clearway_strings.dart';

final class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();

  static const midLevelId = 4101;
  static const dailyId = 4102;
  static const _channelId = 'clearway_reminders';

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  String? _timezoneName;

  Future<void> initialize({ClearwayStrings? strings}) async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    await _refreshTimezone();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            _channelId,
            strings?.notificationChannelName ?? 'Clearway reminders',
            description: strings?.notificationChannelDescription ?? 'Optional reminders for unfinished levels and daily challenges.',
            importance: Importance.defaultImportance,
          ),
        );
    _initialized = true;
  }

  Future<bool> refreshTimezone() async {
    await initialize();
    return _refreshTimezone();
  }

  Future<bool> _refreshTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final changed = _timezoneName != info.identifier;
      _timezoneName = info.identifier;
      tz.setLocalLocation(tz.getLocation(info.identifier));
      return changed;
    } catch (_) {
      final changed = _timezoneName != 'UTC';
      _timezoneName = 'UTC';
      tz.setLocalLocation(tz.UTC);
      return changed;
    }
  }

  Future<bool> requestPermission() async {
    await initialize();
    final granted = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> disable() async {
    await initialize();
    await _plugin.cancel(id: midLevelId);
    await _plugin.cancel(id: dailyId);
  }

  Future<void> cancelMidLevel() async {
    await initialize();
    await _plugin.cancel(id: midLevelId);
  }

  Future<void> cancelDaily() async {
    await initialize();
    await _plugin.cancel(id: dailyId);
  }

  Future<void> scheduleMidLevel({
    required ClearwayStrings strings,
    required bool enabled,
  }) async {
    await initialize();
    await _plugin.cancel(id: midLevelId);
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    var when = now.add(const Duration(hours: 2));
    if (when.hour >= 22 || when.hour < 9) {
      when = _nextQuietHoursEnd(when);
    }
    await _schedule(
      id: midLevelId,
      title: strings.midLevelReminderTitle,
      body: strings.midLevelReminderBody,
      when: when,
      channelName: strings.notificationChannelName,
      channelDescription: strings.notificationChannelDescription,
    );
  }

  Future<void> scheduleDaily({
    required ClearwayStrings strings,
    required bool enabled,
    required String dayKey,
    required bool alreadyPlayed,
  }) async {
    await initialize();
    await _plugin.cancel(id: dailyId);
    if (!enabled || alreadyPlayed) return;
    final now = tz.TZDateTime.now(tz.local);
    final when = tz.TZDateTime(tz.local, now.year, now.month, now.day, 19);
    if (!when.isAfter(now)) return;
    await _schedule(
      id: dailyId,
      title: strings.dailyReminderTitle,
      body: strings.dailyReminderBody,
      when: when,
      payload: 'daily:$dayKey',
      channelName: strings.notificationChannelName,
      channelDescription: strings.notificationChannelDescription,
    );
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime when,
    required String channelName,
    required String channelDescription,
    String? payload,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    scheduledDate: when,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    payload: payload,
  );

  tz.TZDateTime _nextQuietHoursEnd(tz.TZDateTime value) {
    final day = value.hour >= 22 ? value.day + 1 : value.day;
    return tz.TZDateTime(tz.local, value.year, value.month, day, 9);
  }

  String? get timezoneName => _timezoneName;
}
