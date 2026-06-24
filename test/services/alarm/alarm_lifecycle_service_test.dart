import 'package:event_alert/features/alerts/domain/models/alert.dart';
import 'package:event_alert/features/alerts/domain/models/app_alarm_config.dart';
import 'package:event_alert/features/alerts/domain/models/app_notification_config.dart';
import 'package:event_alert/features/alerts/domain/models/recurrence_rule.dart';
import 'package:event_alert/services/alarm/alarm_lifecycle_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseAlarmPayload', () {
    test('parses event payload', () {
      final parsed = parseAlarmPayload('alarm:event:abc');

      expect(parsed?.type, AlarmPayloadType.event);
      expect(parsed?.id, 'abc');
      expect(parsed?.isEvent, isTrue);
      expect(parsed?.isAlert, isFalse);
    });

    test('parses alert payload', () {
      final parsed = parseAlarmPayload('alarm:alert:abc');

      expect(parsed?.type, AlarmPayloadType.alert);
      expect(parsed?.id, 'abc');
      expect(parsed?.isAlert, isTrue);
      expect(parsed?.isEvent, isFalse);
    });

    test('returns null for invalid payloads', () {
      expect(parseAlarmPayload(null), isNull);
      expect(parseAlarmPayload(''), isNull);
      expect(parseAlarmPayload('event:abc'), isNull);
      expect(parseAlarmPayload('alarm:event:'), isNull);
      expect(parseAlarmPayload('alarm:alert:'), isNull);
    });
  });

  group('effectiveSnoozeMinutes', () {
    test('keeps positive values', () {
      expect(effectiveSnoozeMinutes(5), 5);
      expect(effectiveSnoozeMinutes(10), 10);
    });

    test('disables snooze for null, zero or negative values', () {
      expect(effectiveSnoozeMinutes(null), 0);
      expect(effectiveSnoozeMinutes(0), 0);
      expect(effectiveSnoozeMinutes(-1), 0);
    });
  });

  group('nextAlertOccurrenceAfterStop', () {
    test('returns an occurrence strictly after the stop time', () {
      final alert = Alert(
        id: 'alert-1',
        title: 'Diaria',
        timeMinutes: 10 * 60 + 30,
        recurrence: RecurrenceRule(type: RecurrenceType.daily),
        notificationConfig: const AppNotificationConfig(enabled: false),
        alarmConfig: const AppAlarmConfig(enabled: true),
        createdAt: DateTime.utc(2024, 1, 1),
      );
      final stoppedAt = DateTime(2024, 1, 10, 10, 30);

      final next = nextAlertOccurrenceAfterStop(alert, stoppedAt);

      expect(next, DateTime(2024, 1, 11, 10, 30));
      expect(next!.isAfter(stoppedAt), isTrue);
    });
  });
}
