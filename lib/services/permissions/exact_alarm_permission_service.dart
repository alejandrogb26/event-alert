import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ExactAlarmPermissionService {
  ExactAlarmPermissionService._();
  static final ExactAlarmPermissionService instance =
      ExactAlarmPermissionService._();

  static const _channel = MethodChannel(
    'local.alejandrogb.event_alert/exact_alarm',
  );

  Future<bool> canScheduleExactAlarms() async {
    try {
      return await _channel.invokeMethod<bool>('canScheduleExactAlarms') ??
          false;
    } catch (e, st) {
      debugPrint('[ExactAlarmPermissionService] check failed: $e');
      debugPrintStack(stackTrace: st);
      return false;
    }
  }
}
