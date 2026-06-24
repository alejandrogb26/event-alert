import 'package:event_alert/features/alerts/domain/models/alert.dart';
import 'package:event_alert/features/alerts/domain/models/app_alarm_config.dart';
import 'package:event_alert/features/alerts/domain/models/app_notification_config.dart';
import 'package:event_alert/features/alerts/domain/models/recurrence_rule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Alert serialization', () {
    test('toMap and fromMap preserve all values', () {
      final alert = Alert(
        id: 'alert-1',
        title: 'Tomar medicación',
        description: 'Después de comer',
        timeMinutes: 13 * 60 + 45,
        recurrence: RecurrenceRule(
          type: RecurrenceType.weekly,
          interval: 2,
          weekdays: [DateTime.monday, DateTime.wednesday],
          endDate: DateTime.utc(2024, 12, 31),
          maxOccurrences: 10,
        ),
        notificationConfig: const AppNotificationConfig(
          enabled: true,
          minutesBefore: 15,
          customSound: 'assets/notification.mp3',
          vibration: false,
        ),
        alarmConfig: const AppAlarmConfig(
          enabled: true,
          fullScreen: true,
          soundAsset: 'assets/alarm.mp3',
          looping: false,
          snoozeMinutes: 10,
        ),
        isActive: false,
        createdAt: DateTime.utc(2024, 1, 10, 8, 30),
        lastTriggeredAt: DateTime.utc(2024, 1, 11, 13, 45),
      );

      final restored = Alert.fromMap(alert.toMap());

      expect(restored.id, alert.id);
      expect(restored.title, alert.title);
      expect(restored.description, alert.description);
      expect(restored.timeMinutes, alert.timeMinutes);
      expect(restored.isActive, alert.isActive);
      expect(restored.createdAt, alert.createdAt);
      expect(restored.lastTriggeredAt, alert.lastTriggeredAt);

      expect(restored.recurrence.type, RecurrenceType.weekly);
      expect(restored.recurrence.interval, 2);
      expect(restored.recurrence.weekdays, [
        DateTime.monday,
        DateTime.wednesday,
      ]);
      expect(
        restored.recurrence.endDate?.millisecondsSinceEpoch,
        DateTime.utc(2024, 12, 31).millisecondsSinceEpoch,
      );
      expect(restored.recurrence.maxOccurrences, 10);

      expect(restored.notificationConfig.enabled, isTrue);
      expect(restored.notificationConfig.minutesBefore, 15);
      expect(
        restored.notificationConfig.customSound,
        'assets/notification.mp3',
      );
      expect(restored.notificationConfig.vibration, isFalse);

      expect(restored.alarmConfig.enabled, isTrue);
      expect(restored.alarmConfig.fullScreen, isTrue);
      expect(restored.alarmConfig.soundAsset, 'assets/alarm.mp3');
      expect(restored.alarmConfig.looping, isFalse);
      expect(restored.alarmConfig.snoozeMinutes, 10);
    });

    test('fromMap restores SQLite timestamps as UTC DateTime values', () {
      final createdAt = DateTime.utc(2024, 1, 10, 8, 30);
      final lastTriggeredAt = DateTime.utc(2024, 1, 11, 13, 45);
      final restored = Alert.fromMap({
        'id': 'alert-utc',
        'title': 'UTC',
        'description': null,
        'time_minutes': 600,
        'recurrence': '{"type":"daily","interval":1}',
        'notification_config':
            '{"enabled":true,"minutesBefore":0,"vibration":true}',
        'alarm_config':
            '{"enabled":false,"fullScreen":false,"looping":true,"snoozeMinutes":5}',
        'is_active': 1,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_triggered_at': lastTriggeredAt.millisecondsSinceEpoch,
      });

      expect(restored.createdAt.isUtc, isTrue);
      expect(restored.lastTriggeredAt?.isUtc, isTrue);
      expect(restored.createdAt, createdAt);
      expect(restored.lastTriggeredAt, lastTriggeredAt);
    });

    test('config JSON keeps RecurrenceRule, notification and alarm data', () {
      final recurrence = RecurrenceRule(
        type: RecurrenceType.monthly,
        interval: 3,
        dayOfMonth: 15,
        endDate: DateTime.utc(2025, 1, 1),
        maxOccurrences: 4,
      );
      final notification = const AppNotificationConfig(
        enabled: false,
        minutesBefore: 30,
        customSound: 'assets/custom.mp3',
        vibration: false,
      );
      final alarm = const AppAlarmConfig(
        enabled: true,
        fullScreen: true,
        soundAsset: 'assets/alarm.mp3',
        looping: false,
        snoozeMinutes: 20,
      );

      final restoredRecurrence = RecurrenceRule.fromJson(recurrence.toJson());
      final restoredNotification = AppNotificationConfig.fromJson(
        notification.toJson(),
      );
      final restoredAlarm = AppAlarmConfig.fromJson(alarm.toJson());

      expect(restoredRecurrence.type, recurrence.type);
      expect(restoredRecurrence.interval, recurrence.interval);
      expect(restoredRecurrence.dayOfMonth, recurrence.dayOfMonth);
      expect(
        restoredRecurrence.endDate?.millisecondsSinceEpoch,
        recurrence.endDate?.millisecondsSinceEpoch,
      );
      expect(restoredRecurrence.maxOccurrences, recurrence.maxOccurrences);

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
