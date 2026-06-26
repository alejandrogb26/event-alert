import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notification_channels.dart';

/// Envuelve [FlutterLocalNotificationsPlugin] con la API mínima necesaria.
///
/// Singleton. Llamar a [initialize] una vez en main() antes de [runApp].
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  // ─────────────────────────────────────────────────────────────────
  // Inicialización
  // ─────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    tzdata.initializeTimeZones();
    await _setLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/launcher_icon',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(settings: settings);

    // Crea los canales Android. Si ya existen, la operación es idempotente.
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.createNotificationChannel(NotificationChannels.events);
    await androidImpl?.createNotificationChannel(NotificationChannels.alerts);
  }

  /// Detecta la zona horaria local del dispositivo y configura [tz.local].
  ///
  /// Sin esta llamada, [tz.local] es UTC (valor por defecto de initializeTimeZones).
  /// En caso de fallo (emulador con zona no reconocida, etc.), [tz.local] queda
  /// en UTC: las notificaciones se disparan en el instante correcto igualmente
  /// porque el TZDateTime representa el mismo epoch ms.
  Future<void> _setLocalTimezone() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (e) {
      debugPrint(
        '[NotificationService] No se pudo detectar la zona horaria local: $e. '
        'Usando UTC como fallback.',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────────
  // Notificación inmediata de prueba
  // ─────────────────────────────────────────────────────────────────

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      NotificationChannels.eventsId,
      'Eventos',
      channelDescription: 'Notificaciones de eventos programados',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _plugin.show(
      id: 0,
      title: 'Notificaciones activas',
      body: 'Las notificaciones de Event Alert funcionan correctamente.',
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Programar notificación
  // ─────────────────────────────────────────────────────────────────

  /// Programa una notificación para el instante [scheduledDateTime].
  ///
  /// [scheduledDateTime] puede estar en UTC o local — se convierte a hora
  /// local del dispositivo y se construye [tz.TZDateTime] con [tz.local]
  /// (zona real del dispositivo, inicializada en [initialize]).
  ///
  /// Si el instante ya pasó, la llamada es un no-op.
  ///
  /// Usa [AndroidScheduleMode.inexactAllowWhileIdle] (no exacta). En fases
  /// posteriores se migrará a alarmas exactas con USE_EXACT_ALARM.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    required String channelId,
    String? payload,
  }) async {
    final local = scheduledDateTime.toLocal();
    if (!local.isAfter(DateTime.now())) return;

    // TZDateTime en zona local real del dispositivo para que el sistema
    // respete DST y ajuste el disparo a la hora de reloj correcta.
    final tzScheduled = tz.TZDateTime.from(local, tz.local);

    final channelName = channelId == NotificationChannels.eventsId
        ? NotificationChannels.events.name
        : NotificationChannels.alerts.name;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tzScheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Cancelar
  // ─────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) => _plugin.cancel(id: id);

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await _plugin.cancel(id: id);
    }
  }
}
