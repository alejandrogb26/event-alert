import 'package:flutter/foundation.dart';

import '../../core/utils/recurrence_calculator.dart';
import '../../core/utils/stable_id.dart';
import '../../features/alerts/data/alert_dao.dart';
import '../../features/alerts/data/alert_repository_impl.dart';
import '../../features/alerts/domain/models/alert.dart';
import '../../features/events/data/event_dao.dart';
import '../../features/events/data/event_repository_impl.dart';
import '../../features/events/domain/models/calendar_event.dart';
import '../database/database_service.dart';
import '../notifications/notification_channels.dart';
import '../notifications/notification_service.dart';
import '../permissions/permission_service.dart';

/// Orquesta [NotificationService] para programar, cancelar y reprogramar
/// notificaciones de alertas y eventos.
///
/// Las alarmas sonoras están temporalmente desactivadas mientras el paquete
/// `alarm` no sea compatible con compileSdk 35+. La configuración de alarma
/// se sigue guardando en SQLite; reactivar integrando [AlarmService] cuando
/// el paquete esté disponible.
///
/// Singleton. Mantiene sus propias instancias de DAO/repositorio sobre el
/// [DatabaseService] global.
class SchedulingService {
  SchedulingService._();
  static final SchedulingService instance = SchedulingService._();

  final _notif = NotificationService.instance;

  late final _alertRepo =
      AlertRepositoryImpl(AlertDao(DatabaseService.instance));
  late final _eventRepo =
      EventRepositoryImpl(EventDao(DatabaseService.instance));

  // ─────────────────────────────────────────────────────────────────
  // Eventos
  // ─────────────────────────────────────────────────────────────────

  Future<void> scheduleEvent(CalendarEvent event) async {
    await _scheduleEventNotification(event);
    // TODO(alarm): programar alarma sonora si event.alarmConfig.enabled.
  }

  Future<void> _scheduleEventNotification(CalendarEvent event) async {
    if (!event.notificationConfig.enabled) return;

    final perm = await PermissionService.instance.checkNotificationPermission();
    if (perm != NotificationPermissionStatus.granted) return;

    final trigger = event.startDateTime
        .toLocal()
        .subtract(Duration(minutes: event.notificationConfig.minutesBefore));
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
    // TODO(alarm): cancelar alarma sonora: AlarmService.instance.cancel(stableId('alarm:event:${event.id}'))
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
  /// TODO(alarm): cuando AlarmService esté disponible, programar también la
  /// alarma sonora para [next] si alert.alarmConfig.enabled.
  ///
  /// TODO(reprogramación): implementar reprogramación automática tras disparo
  /// mediante alarma exacta o WorkManager (Fase 6B/7).
  Future<void> scheduleAlert(Alert alert) async {
    if (!alert.isActive) return;
    if (!alert.notificationConfig.enabled) return;

    final next = nextOccurrence(
      rule: alert.recurrence,
      timeMinutes: alert.timeMinutes,
      from: DateTime.now(),
    );
    if (next == null) return;

    await _scheduleAlertNotification(alert, next);
    // TODO(alarm): await _scheduleAlertAlarm(alert, next);
  }

  Future<void> _scheduleAlertNotification(Alert alert, DateTime next) async {
    final perm = await PermissionService.instance.checkNotificationPermission();
    if (perm != NotificationPermissionStatus.granted) return;

    final trigger =
        next.subtract(Duration(minutes: alert.notificationConfig.minutesBefore));
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
    // TODO(alarm): cancelar alarma sonora: AlarmService.instance.cancel(stableId('alarm:alert:${alert.id}'))
  }

  Future<void> rescheduleAlert(Alert alert) async {
    await cancelAlert(alert);
    await scheduleAlert(alert);
  }

  // ─────────────────────────────────────────────────────────────────
  // Reprogramación global
  // ─────────────────────────────────────────────────────────────────

  /// Cancela y reprograma notificaciones para todos los registros.
  ///
  /// Se llama al arrancar la app para restaurar lo que se perdió tras reinicio
  /// del dispositivo ([BOOT_COMPLETED]) o actualización ([MY_PACKAGE_REPLACED]).
  Future<void> rescheduleAll() async {
    final alerts = await _alertRepo.findAll();
    for (final alert in alerts) {
      try {
        await rescheduleAlert(alert);
      } catch (e) {
        debugPrint(
            '[SchedulingService] rescheduleAlert(${alert.id}) failed: $e');
      }
    }

    final events = await _eventRepo.findAll();
    for (final event in events) {
      try {
        await rescheduleEvent(event);
      } catch (e) {
        debugPrint(
            '[SchedulingService] rescheduleEvent(${event.id}) failed: $e');
      }
    }
  }
}
