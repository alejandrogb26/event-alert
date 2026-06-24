import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'features/alarm/presentation/screens/alarm_ringing_screen.dart';
import 'navigation/main_screen.dart';
import 'services/alarm/alarm_service.dart';

class EventAlertApp extends StatefulWidget {
  const EventAlertApp({super.key});

  @override
  State<EventAlertApp> createState() => _EventAlertAppState();
}

class _EventAlertAppState extends State<EventAlertApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final Set<int> _openAlarmRoutes = <int>{};
  StreamSubscription<ActiveAlarm>? _alarmSubscription;

  @override
  void initState() {
    super.initState();
    _alarmSubscription = AlarmService.instance.ringingAlarms.listen(
      _openAlarmScreen,
    );
  }

  @override
  void dispose() {
    _alarmSubscription?.cancel();
    super.dispose();
  }

  void _openAlarmScreen(ActiveAlarm alarm) {
    if (!_openAlarmRoutes.add(alarm.id)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = _navigatorKey.currentState;
      if (navigator == null) {
        _openAlarmRoutes.remove(alarm.id);
        return;
      }

      navigator
          .push<void>(
            MaterialPageRoute(
              builder: (_) => AlarmRingingScreen(alarm: alarm),
              fullscreenDialog: true,
            ),
          )
          .whenComplete(() => _openAlarmRoutes.remove(alarm.id));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Event Alert',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,

      // Locale española para DatePicker, TimePicker y demás widgets del sistema.
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const MainScreen(),
    );
  }
}
