import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract final class NotificationChannels {
  static const String eventsId = 'event_alert_events';
  static const String alertsId = 'event_alert_alerts';

  static const AndroidNotificationChannel events = AndroidNotificationChannel(
    eventsId,
    'Eventos',
    description: 'Notificaciones de eventos programados',
    importance: Importance.high,
  );

  static const AndroidNotificationChannel alerts = AndroidNotificationChannel(
    alertsId,
    'Alertas',
    description: 'Notificaciones de alertas recurrentes',
    importance: Importance.high,
  );
}
