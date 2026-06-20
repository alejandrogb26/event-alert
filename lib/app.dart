import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'navigation/main_screen.dart';

class EventAlertApp extends StatelessWidget {
  const EventAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
