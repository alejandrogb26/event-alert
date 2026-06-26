import 'package:flutter/foundation.dart';

import '../../core/utils/recurrence_calculator.dart';
import '../../core/utils/stable_id.dart';
import '../../features/alerts/data/alert_dao.dart';
import '../../features/alerts/data/alert_repository_impl.dart';
import '../../features/alerts/domain/models/alert.dart';
import '../../features/events/data/event_dao.dart';
import '../../features/events/data/event_repository_impl.dart';
import '../../features/events/domain/models/calendar_event.dart';
import '../alarm/alarm_service.dart';
import '../database/database_service.dart';
import '../notifications/notification_channels.dart';
import '../notifications/notification_service.dart';
import '../permissions/permission_service.dart';

/// Orquesta [NotificationService] para programar, cancelar y reprogramar
/// notificaciones de alertas y eventos.
///
/// Singleton. Mantiene sus propias instancias de DAO/repositorio sobre el
/// [DatabaseService] global.
class SchedulingService {
  SchedulingService._();
  static final SchedulingService instance = SchedulingService._();

  final _notif = NotificationService.instance;
  final _alarm = AlarmService.instance;

  late final _alertRepo = AlertRepositoryImpl(
    AlertDao(DatabaseService.instance),
  );
  late final _eventRepo = EventRepositoryImpl(
    EventDao(DatabaseService.instance),
  );

  // ─────────────────────────────────────────────────────────────────
  // Eventos
  // ─────────────────────────────────────────────────────────────────

  Future<void> scheduleEvent(CalendarEvent event) async {
    await _scheduleEventNotification(event);
    await _scheduleEventAlarm(event);
  }

  Future<void> _scheduleEventNotification(CalendarEvent event) async {
    if (!event.notificationConfig.enabled) return;

    final perm = await PermissionService.instance.checkNotificationPermission();
    if (perm != NotificationPermissionStatus.granted) return;

    final trigger = event.startDateTime.toLocal().subtract(
      Duration(minutes: event.notificationConfig.minutesBefore),
    );
    if (!trigger.isAfter(DateTime.now())) return;

    await _notif.scheduleNotification(
      id: stableId('event:${event.id}'),
      title: event.title,
      body: (event.description?.isNotEmpty ?? false)
          ? event.description!
          : 'Tienes un evento programado.',
      scheduledDateTime: trigger,
      channelId: NotificationChannels.eventsId,
      payload: 'event:${event.id}',
    );
  }

  Future<void> cancelEvent(CalendarEvent event) async {
    await _notif.cancel(stableId('event:${event.id}'));
    final alarmId = stableId('alarm:event:${event.id}');
    await _alarm.cancel(alarmId);
  }

  Future<void> _scheduleEventAlarm(CalendarEvent event) async {
    final trigger = event.startDateTime.toLocal();
    final alarmId = stableId('alarm:event:${event.id}');
    final isFuture = trigger.isAfter(DateTime.now());
    debugPrint(
      '[alarm-audit] schedule requested\n'
      'id=$alarmId\n'
      'payload=alarm:event:${event.id}\n'
      'trigger local=$trigger\n'
      'trigger UTC=${trigger.toUtc()}\n'
      'isFuture=$isFuture\n'
      'enabled=${event.alarmConfig.enabled}',
    );

    if (!event.alarmConfig.enabled) return;
    if (!isFuture) return;

    await _alarm.scheduleAlarm(
      id: alarmId,
      title: event.title,
      body: (event.description?.isNotEmpty ?? false)
          ? event.description!
          : 'Tienes un evento programado.',
      dateTime: trigger,
      assetAudioPath: event.alarmConfig.soundAsset,
      loopAudio: event.alarmConfig.looping,
      payload: 'alarm:event:${event.id}',
    );
  }

  Future<void> rescheduleEvent(CalendarEvent event) async {
    await cancelEvent(event);
    await scheduleEvent(event);
  }

  // ─────────────────────────────────────────────────────────────────
  // Alertas
  // ─────────────────────────────────────────────────────────────────

  /// Programa la PRÓXIMA notificación de [alert] a partir de ahora.
  ///
  /// Solo se programa una ocurrencia a la vez.
  ///
  /// TODO(alarm): Reprogramar la siguiente ocurrencia de una alerta recurrente
  /// tras detener o posponer la alarma actual, incluso si la app estaba cerrada.
  Future<void> scheduleAlert(Alert alert, {DateTime? from}) async {
    if (!alert.isActive) return;

    final next = nextOccurrence(
      rule: alert.recurrence,
      timeMinutes: alert.timeMinutes,
      from: from ?? DateTime.now(),
    );
    if (next == null) return;

    await _scheduleAlertNotification(alert, next);
    await _scheduleAlertAlarm(alert, next);
  }

  Future<void> _scheduleAlertNotification(Alert alert, DateTime next) async {
    if (!alert.notificationConfig.enabled) return;

    final perm = await PermissionService.instance.checkNotificationPermission();
    if (perm != NotificationPermissionStatus.granted) return;

    final trigger = next.subtract(
      Duration(minutes: alert.notificationConfig.minutesBefore),
    );
    if (!trigger.isAfter(DateTime.now())) return;

    await _notif.scheduleNotification(
      id: stableId('alert:${alert.id}'),
      title: alert.title,
      body: (alert.description?.isNotEmpty ?? false)
          ? alert.description!
          : 'Tienes una alerta pendiente.',
      scheduledDateTime: trigger,
      channelId: NotificationChannels.alertsId,
      payload: 'alert:${alert.id}',
    );
  }

  Future<void> cancelAlert(Alert alert) async {
    await _notif.cancel(stableId('alert:${alert.id}'));
    final alarmId = stableId('alarm:alert:${alert.id}');
    await _alarm.cancel(alarmId);
  }

  Future<void> _scheduleAlertAlarm(Alert alert, DateTime next) async {
    final trigger = next.toLocal();
    final alarmId = stableId('alarm:alert:${alert.id}');
    final isFuture = trigger.isAfter(DateTime.now());
    debugPrint(
      '[alarm-audit] schedule requested\n'
      'id=$alarmId\n'
      'payload=alarm:alert:${alert.id}\n'
      'trigger local=$trigger\n'
      'trigger UTC=${trigger.toUtc()}\n'
      'isFuture=$isFuture\n'
      'enabled=${alert.alarmConfig.enabled}',
    );

    if (!alert.alarmConfig.enabled) return;
    if (!isFuture) return;

    await _alarm.scheduleAlarm(
      id: alarmId,
      title: alert.title,
      body: (alert.description?.isNotEmpty ?? false)
          ? alert.description!
          : 'Tienes una alerta pendiente.',
      dateTime: trigger,
      assetAudioPath: alert.alarmConfig.soundAsset,
      loopAudio: alert.alarmConfig.looping,
      payload: 'alarm:alert:${alert.id}',
    );
  }

  Future<void> rescheduleAlert(
    Alert alert, {
    DateTime? from,
    bool cancelExisting = true,
  }) async {
    if (cancelExisting) {
      await cancelAlert(alert);
    }
    await scheduleAlert(alert, from: from);
  }

  // ─────────────────────────────────────────────────────────────────
  // Reprogramación global
  // ─────────────────────────────────────────────────────────────────

  /// Cancela y reprograma notificaciones para todos los registros.
  ///
  /// Se llama al arrancar la app para restaurar lo que se perdió tras reinicio
  /// del dispositivo ([BOOT_COMPLETED]) o actualización ([MY_PACKAGE_REPLACED]).
  ///
  /// Con targetSdk 35 no intentamos iniciar reproducción de audio propia desde
  /// BOOT_COMPLETED. Al abrir la app, este método reprograma el estado esperado;
  /// el receptor del plugin `alarm` solo restaura alarmas que él tenía guardadas.
  Future<void> rescheduleAll() async {
    final alerts = await _alertRepo.findAll();
    for (final alert in alerts) {
      try {
        await rescheduleAlert(alert);
      } catch (e, st) {
        debugPrint(
          '[alarm-audit] error=$e\n'
          'stacktrace=$st',
        );
        debugPrint(
          '[SchedulingService] rescheduleAlert(${alert.id}) failed: $e',
        );
      }
    }

    final events = await _eventRepo.findAll();
    for (final event in events) {
      try {
        await rescheduleEvent(event);
      } catch (e, st) {
        debugPrint(
          '[alarm-audit] error=$e\n'
          'stacktrace=$st',
        );
        debugPrint(
          '[SchedulingService] rescheduleEvent(${event.id}) failed: $e',
        );
      }
    }
  }
}
