import 'dart:convert';

import 'app_alarm_config.dart';
import 'app_notification_config.dart';
import 'recurrence_rule.dart';

const _absent = Object();

class Alert {
  Alert({
    required this.id,
    required this.title,
    this.description,
    required this.timeMinutes,
    required this.recurrence,
    required this.notificationConfig,
    required this.alarmConfig,
    this.isActive = true,
    required this.createdAt,
    this.lastTriggeredAt,
  }) : assert(
          timeMinutes >= 0 && timeMinutes <= 1439,
          'timeMinutes debe estar entre 0 (00:00) y 1439 (23:59)',
        );

  final String id;
  final String title;
  final String? description;

  /// Hora del día en minutos desde medianoche. 0 = 00:00, 570 = 09:30, 1439 = 23:59.
  final int timeMinutes;

  final RecurrenceRule recurrence;
  final AppNotificationConfig notificationConfig;
  final AppAlarmConfig alarmConfig;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;

  /// Serializa a un mapa apto para insertar en SQLite.
  Map<String, Object?> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'time_minutes': timeMinutes,
        'recurrence': jsonEncode(recurrence.toJson()),
        'notification_config': jsonEncode(notificationConfig.toJson()),
        'alarm_config': jsonEncode(alarmConfig.toJson()),
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'last_triggered_at': lastTriggeredAt?.millisecondsSinceEpoch,
      };

  /// Construye una instancia desde una fila de SQLite.
  factory Alert.fromMap(Map<String, Object?> map) => Alert(
        id: map['id'] as String,
        title: map['title'] as String,
        description: map['description'] as String?,
        timeMinutes: map['time_minutes'] as int,
        recurrence: RecurrenceRule.fromJson(
          jsonDecode(map['recurrence'] as String) as Map<String, dynamic>,
        ),
        notificationConfig: AppNotificationConfig.fromJson(
          jsonDecode(map['notification_config'] as String)
              as Map<String, dynamic>,
        ),
        alarmConfig: AppAlarmConfig.fromJson(
          jsonDecode(map['alarm_config'] as String) as Map<String, dynamic>,
        ),
        isActive: (map['is_active'] as int) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
          isUtc: true,
        ),
        lastTriggeredAt: map['last_triggered_at'] != null
            ? DateTime.fromMillisecondsSinceEpoch(
                map['last_triggered_at'] as int,
                isUtc: true,
              )
            : null,
      );

  Alert copyWith({
    String? id,
    String? title,
    Object? description = _absent,
    int? timeMinutes,
    RecurrenceRule? recurrence,
    AppNotificationConfig? notificationConfig,
    AppAlarmConfig? alarmConfig,
    bool? isActive,
    DateTime? createdAt,
    Object? lastTriggeredAt = _absent,
  }) =>
      Alert(
        id: id ?? this.id,
        title: title ?? this.title,
        description: identical(description, _absent)
            ? this.description
            : description as String?,
        timeMinutes: timeMinutes ?? this.timeMinutes,
        recurrence: recurrence ?? this.recurrence,
        notificationConfig: notificationConfig ?? this.notificationConfig,
        alarmConfig: alarmConfig ?? this.alarmConfig,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
        lastTriggeredAt: identical(lastTriggeredAt, _absent)
            ? this.lastTriggeredAt
            : lastTriggeredAt as DateTime?,
      );

  @override
  String toString() =>
      'Alert(id: $id, title: $title, timeMinutes: $timeMinutes, '
      'isActive: $isActive, recurrence: $recurrence)';
}
