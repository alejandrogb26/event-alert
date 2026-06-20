import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/notifications/notification_service.dart';
import 'services/scheduling/scheduling_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_ES', null);

  // TODO(alarm): cuando el paquete alarm sea compatible con compileSdk 35+,
  // volver a añadir Alarm.init() aquí antes de rescheduleAll().

  try {
    await NotificationService.instance.initialize();
    await SchedulingService.instance.rescheduleAll();
  } catch (e, st) {
    debugPrint('[main] Servicios de scheduling failed: $e');
    debugPrintStack(stackTrace: st);
  }

  runApp(const ProviderScope(child: EventAlertApp()));
}