import 'dart:async';

import 'package:alarm/alarm.dart';
import 'package:flutter/foundation.dart';

class ActiveAlarm {
  const ActiveAlarm({
    required this.id,
    required this.title,
    required this.body,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final String? payload;
}

/// Encapsula el paquete `alarm` para que el resto de la app no dependa de su
/// API directamente.
class AlarmService {
  AlarmService._();
  static final AlarmService instance = AlarmService._();

  final _ringingController = StreamController<ActiveAlarm>.broadcast();
  final Set<int> _emittedRingingIds = <int>{};
  StreamSubscription<dynamic>? _ringingSubscription;

  Stream<ActiveAlarm> get ringingAlarms => _ringingController.stream;

  Future<void> initialize() async {
    await Alarm.init();
    _ringingSubscription ??= Alarm.ringing.listen(_handleRingingAlarms);
  }

  Future<bool> scheduleAlarm({
    required int id,
    required DateTime dateTime,
    required String title,
    required String body,
    String? assetAudioPath,
    bool loopAudio = true,
    String? payload,
  }) async {
    final local = dateTime.toLocal();
    if (!local.isAfter(DateTime.now())) return false;

    final settings = AlarmSettings(
      id: id,
      dateTime: local,
      assetAudioPath: assetAudioPath,
      loopAudio: loopAudio,
      vibrate: true,
      warningNotificationOnKill: false,
      androidFullScreenIntent: false,
      allowSameSecondScheduling: true,
      volumeSettings: const VolumeSettings.fixed(),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'Detener',
      ),
      payload: payload,
    );

    return Alarm.set(alarmSettings: settings);
  }

  Future<bool> cancel(int id) => Alarm.stop(id);

  Future<void> stopAlarm(int id) async {
    try {
      await Alarm.stop(id);
      _emittedRingingIds.remove(id);
    } catch (e, st) {
      debugPrint('[AlarmService] stopAlarm($id) failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> snoozeAlarm({
    required int id,
    required Duration duration,
  }) async {
    AlarmSettings? settings;
    try {
      settings = await Alarm.getAlarm(id);
      if (settings == null) {
        debugPrint(
          '[AlarmService] snoozeAlarm($id): alarm settings not found.',
        );
        await stopAlarm(id);
        return;
      }

      await Alarm.stop(id);
      _emittedRingingIds.remove(id);

      final snoozed = settings.copyWith(dateTime: DateTime.now().add(duration));
      await Alarm.set(alarmSettings: snoozed);
    } catch (e, st) {
      debugPrint('[AlarmService] snoozeAlarm($id) failed: $e');
      debugPrintStack(stackTrace: st);
      try {
        await stopAlarm(id);
      } catch (_) {
        // El error original es el relevante para la UI y el log.
      }
      rethrow;
    }
  }

  Future<void> cancelMany(Iterable<int> ids) async {
    for (final id in ids) {
      await cancel(id);
    }
  }

  void _handleRingingAlarms(dynamic alarmSet) {
    final alarms = List<AlarmSettings>.from(alarmSet.alarms as Iterable);
    final activeIds = alarms
        .map<int>((AlarmSettings alarm) => alarm.id)
        .toSet();
    _emittedRingingIds.removeWhere((id) => !activeIds.contains(id));

    for (final alarm in alarms) {
      if (!_emittedRingingIds.add(alarm.id)) continue;
      _ringingController.add(
        ActiveAlarm(
          id: alarm.id,
          title: alarm.notificationSettings.title,
          body: alarm.notificationSettings.body,
          payload: alarm.payload,
        ),
      );
    }
  }
}
