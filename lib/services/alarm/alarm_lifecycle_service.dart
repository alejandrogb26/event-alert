import 'package:flutter/foundation.dart';

import '../../core/utils/recurrence_calculator.dart';
import '../../features/alerts/data/alert_dao.dart';
import '../../features/alerts/data/alert_repository_impl.dart';
import '../../features/alerts/domain/models/alert.dart';
import '../../features/events/data/event_dao.dart';
import '../../features/events/data/event_repository_impl.dart';
import '../database/database_service.dart';
import '../scheduling/scheduling_service.dart';
import 'alarm_service.dart';

enum AlarmPayloadType { event, alert }

class AlarmPayloadInfo {
  const AlarmPayloadInfo({required this.type, required this.id});

  final AlarmPayloadType type;
  final String id;

  bool get isEvent => type == AlarmPayloadType.event;
  bool get isAlert => type == AlarmPayloadType.alert;
}

class AlarmLifecycleDetails {
  const AlarmLifecycleDetails({
    required this.payloadInfo,
    required this.snoozeMinutes,
  });

  final AlarmPayloadInfo? payloadInfo;
  final int snoozeMinutes;

  bool get canSnooze => snoozeMinutes > 0;
}

AlarmPayloadInfo? parseAlarmPayload(String? payload) {
  if (payload == null) return null;

  const eventPrefix = 'alarm:event:';
  if (payload.startsWith(eventPrefix)) {
    final id = payload.substring(eventPrefix.length);
    if (id.isEmpty) return null;
    return AlarmPayloadInfo(type: AlarmPayloadType.event, id: id);
  }

  const alertPrefix = 'alarm:alert:';
  if (payload.startsWith(alertPrefix)) {
    final id = payload.substring(alertPrefix.length);
    if (id.isEmpty) return null;
    return AlarmPayloadInfo(type: AlarmPayloadType.alert, id: id);
  }

  return null;
}

int effectiveSnoozeMinutes(int? value) {
  if (value == null || value <= 0) return 0;
  return value;
}

DateTime? nextAlertOccurrenceAfterStop(Alert alert, DateTime stoppedAt) {
  return nextOccurrence(
    rule: alert.recurrence,
    timeMinutes: alert.timeMinutes,
    from: stoppedAt,
  );
}

class AlarmLifecycleService {
  AlarmLifecycleService._();
  static final AlarmLifecycleService instance = AlarmLifecycleService._();

  final _alarmService = AlarmService.instance;
  final _schedulingService = SchedulingService.instance;
  final _alertRepo = AlertRepositoryImpl(AlertDao(DatabaseService.instance));
  final _eventRepo = EventRepositoryImpl(EventDao(DatabaseService.instance));

  Future<AlarmLifecycleDetails> resolve(ActiveAlarm alarm) async {
    final info = parseAlarmPayload(alarm.payload);
    final snoozeMinutes = await _resolveSnoozeMinutes(info);

    return AlarmLifecycleDetails(
      payloadInfo: info,
      snoozeMinutes: snoozeMinutes,
    );
  }

  Future<void> stop(ActiveAlarm alarm) async {
    final info = parseAlarmPayload(alarm.payload);

    switch (info?.type) {
      case AlarmPayloadType.alert:
        await _stopAlertAlarm(alarm, info!.id);
      case AlarmPayloadType.event:
        await _alarmService.stopAlarm(alarm.id);
      case null:
        await _alarmService.stopAlarm(alarm.id);
    }
  }

  Future<void> snooze(ActiveAlarm alarm) async {
    final info = parseAlarmPayload(alarm.payload);
    final snoozeMinutes = await _resolveSnoozeMinutes(info);
    if (snoozeMinutes <= 0) return;

    // TODO(alarm): decidir si una alarma pospuesta debe crear también una
    // notificación local propia o solo reprogramar el audio.
    await _alarmService.snoozeAlarm(
      id: alarm.id,
      duration: Duration(minutes: snoozeMinutes),
    );
  }

  Future<int> _resolveSnoozeMinutes(AlarmPayloadInfo? info) async {
    if (info == null) return 0;

    try {
      return switch (info.type) {
        AlarmPayloadType.alert => effectiveSnoozeMinutes(
          (await _alertRepo.findById(info.id))?.alarmConfig.snoozeMinutes,
        ),
        AlarmPayloadType.event => effectiveSnoozeMinutes(
          (await _eventRepo.findById(info.id))?.alarmConfig.snoozeMinutes,
        ),
      };
    } catch (e, st) {
      debugPrint('[AlarmLifecycleService] resolve snooze failed: $e');
      debugPrintStack(stackTrace: st);
      return 0;
    }
  }

  Future<void> _stopAlertAlarm(ActiveAlarm alarm, String alertId) async {
    await _alarmService.stopAlarm(alarm.id);

    final alert = await _alertRepo.findById(alertId);
    if (alert == null) {
      debugPrint(
        '[AlarmLifecycleService] Alert $alertId not found after stop.',
      );
      return;
    }

    final stoppedAt = DateTime.now().toUtc();
    final updated = alert.copyWith(lastTriggeredAt: stoppedAt);
    await _alertRepo.save(updated);

    await _schedulingService.rescheduleAlert(
      updated,
      from: stoppedAt.toLocal(),
      cancelExisting: false,
    );
  }
}
