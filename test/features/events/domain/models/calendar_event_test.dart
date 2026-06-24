import 'package:event_alert/features/alerts/domain/models/app_alarm_config.dart';
import 'package:event_alert/features/alerts/domain/models/app_notification_config.dart';
import 'package:event_alert/features/events/domain/models/calendar_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarEvent serialization', () {
    test('toMap and fromMap preserve all values', () {
      final event = CalendarEvent(
        id: 'event-1',
        title: 'Reunión',
        description: 'Planificación semanal',
        startDateTime: DateTime.utc(2024, 1, 10, 15, 30),
        duration: const Duration(minutes: 90),
        notificationConfig: const AppNotificationConfig(
          enabled: true,
          minutesBefore: 30,
          customSound: 'assets/event.mp3',
          vibration: false,
        ),
        alarmConfig: const AppAlarmConfig(
          enabled: true,
          fullScreen: false,
          soundAsset: 'assets/alarm.mp3',
          looping: true,
          snoozeMinutes: 5,
        ),
        createdAt: DateTime.utc(2024, 1, 1, 9),
      );

      final restored = CalendarEvent.fromMap(event.toMap());

      expect(restored.id, event.id);
      expect(restored.title, event.title);
      expect(restored.description, event.description);
      expect(restored.startDateTime, event.startDateTime);
      expect(restored.duration, event.duration);
      expect(restored.createdAt, event.createdAt);

      expect(restored.notificationConfig.enabled, isTrue);
      expect(restored.notificationConfig.minutesBefore, 30);
      expect(restored.notificationConfig.customSound, 'assets/event.mp3');
      expect(restored.notificationConfig.vibration, isFalse);

      expect(restored.alarmConfig.enabled, isTrue);
      expect(restored.alarmConfig.fullScreen, isFalse);
      expect(restored.alarmConfig.soundAsset, 'assets/alarm.mp3');
      expect(restored.alarmConfig.looping, isTrue);
      expect(restored.alarmConfig.snoozeMinutes, 5);
    });

    test('fromMap restores SQLite timestamps as UTC DateTime values', () {
      final start = DateTime.utc(2024, 1, 10, 15, 30);
      final createdAt = DateTime.utc(2024, 1, 1, 9);
      final restored = CalendarEvent.fromMap({
        'id': 'event-utc',
        'title': 'UTC',
        'description': null,
        'start_datetime': start.millisecondsSinceEpoch,
        'duration_ms': null,
        'notification_config':
            '{"enabled":true,"minutesBefore":0,"vibration":true}',
        'alarm_config':
            '{"enabled":false,"fullScreen":false,"looping":true,"snoozeMinutes":5}',
        'created_at': createdAt.millisecondsSinceEpoch,
      });

      expect(restored.startDateTime.isUtc, isTrue);
      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.startDateTime, start);
      expect(restored.createdAt, createdAt);
    });

    test('duration is converted to and from duration_ms', () {
      final event = CalendarEvent(
        id: 'event-duration',
        title: 'Duración',
        startDateTime: DateTime.utc(2024, 1, 10, 15),
        duration: const Duration(hours: 2, minutes: 15),
        notificationConfig: const AppNotificationConfig(),
        alarmConfig: const AppAlarmConfig(),
        createdAt: DateTime.utc(2024, 1, 1),
      );

      final map = event.toMap();
      expect(
        map['duration_ms'],
        const Duration(hours: 2, minutes: 15).inMilliseconds,
      );

      final restored = CalendarEvent.fromMap(map);
      expect(restored.duration, const Duration(hours: 2, minutes: 15));
    });

    test('notification and alarm JSON keep all data', () {
      final notification = const AppNotificationConfig(
        enabled: false,
        minutesBefore: 1440,
        customSound: 'assets/custom.mp3',
        vibration: false,
      );
      final alarm = const AppAlarmConfig(
        enabled: true,
        fullScreen: true,
        soundAsset: 'assets/alarm.mp3',
        looping: false,
        snoozeMinutes: 30,
      );

      final restoredNotification = AppNotificationConfig.fromJson(
        notification.toJson(),
      );
      final restoredAlarm = AppAlarmConfig.fromJson(alarm.toJson());

      expect(restoredNotification.enabled, notification.enabled);
      expect(restoredNotification.minutesBefore, notification.minutesBefore);
      expect(restoredNotification.customSound, notification.customSound);
      expect(restoredNotification.vibration, notification.vibration);

      expect(restoredAlarm.enabled, alarm.enabled);
      expect(restoredAlarm.fullScreen, alarm.fullScreen);
      expect(restoredAlarm.soundAsset, alarm.soundAsset);
      expect(restoredAlarm.looping, alarm.looping);
      expect(restoredAlarm.snoozeMinutes, alarm.snoozeMinutes);
    });
  });
}
