import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/alarm/alarm_service.dart';
import 'services/notifications/notification_service.dart';
import 'services/permissions/exact_alarm_permission_service.dart';
import 'services/scheduling/scheduling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  try {
    final canScheduleExactAlarms = await ExactAlarmPermissionService.instance
        .canScheduleExactAlarms();
    debugPrint('[main] canScheduleExactAlarms=$canScheduleExactAlarms');
    await AlarmService.instance.initialize();
  } catch (e, st) {
    debugPrint('[main] AlarmService init failed: $e');
    debugPrintStack(stackTrace: st);
  }

  try {
    await NotificationService.instance.initialize();
    await SchedulingService.instance.rescheduleAll();
  } catch (e, st) {
    debugPrint('[main] Servicios de scheduling failed: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const ProviderScope(child: EventAlertApp()));
}
