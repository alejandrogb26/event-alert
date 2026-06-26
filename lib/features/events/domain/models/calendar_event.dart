import 'dart:convert';

import '../../../alerts/domain/models/app_alarm_config.dart';
import '../../../alerts/domain/models/app_notification_config.dart';

const _absent = Object();

class CalendarEvent {
  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startDateTime,
    this.duration,
    required this.notificationConfig,
    required this.alarmConfig,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String? description;

  /// Fecha y hora de inicio del evento, en UTC.
  final DateTime startDateTime;

  /// Duración del evento. null = sin duración definida (evento de punto en el tiempo).
  final Duration? duration;

  final AppNotificationConfig notificationConfig;
  final AppAlarmConfig alarmConfig;
  final DateTime createdAt;

  /// Serializa a un mapa apto para insertar en SQLite.
  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'start_datetime': startDateTime.millisecondsSinceEpoch,
    'duration_ms': duration?.inMilliseconds,
    'notification_config': jsonEncode(notificationConfig.toJson()),
    'alarm_config': jsonEncode(alarmConfig.toJson()),
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  /// Construye una instancia desde una fila de SQLite.
  factory CalendarEvent.fromMap(Map<String, Object?> map) => CalendarEvent(
    id: map['id'] as String,
    title: map['title'] as String,
    description: map['description'] as String?,
    startDateTime: DateTime.fromMillisecondsSinceEpoch(
      map['start_datetime'] as int,
      isUtc: true,
    ),
    duration: map['duration_ms'] != null
        ? Duration(milliseconds: map['duration_ms'] as int)
        : null,
    notificationConfig: AppNotificationConfig.fromJson(
      jsonDecode(map['notification_config'] as String) as Map<String, dynamic>,
    ),
    alarmConfig: AppAlarmConfig.fromJson(
      jsonDecode(map['alarm_config'] as String) as Map<String, dynamic>,
    ),
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      map['created_at'] as int,
      isUtc: true,
    ),
  );

  CalendarEvent copyWith({
    String? id,
    String? title,
    Object? description = _absent,
    DateTime? startDateTime,
    Object? duration = _absent,
    AppNotificationConfig? notificationConfig,
    AppAlarmConfig? alarmConfig,
    DateTime? createdAt,
  }) => CalendarEvent(
    id: id ?? this.id,
    title: title ?? this.title,
    description: identical(description, _absent)
        ? this.description
        : description as String?,
    startDateTime: startDateTime ?? this.startDateTime,
    duration: identical(duration, _absent)
        ? this.duration
        : duration as Duration?,
    notificationConfig: notificationConfig ?? this.notificationConfig,
    alarmConfig: alarmConfig ?? this.alarmConfig,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() =>
      'CalendarEvent(id: $id, title: $title, startDateTime: $startDateTime, '
      'duration: $duration)';
}
