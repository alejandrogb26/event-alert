import 'package:flutter/material.dart';

import '../../../../services/alarm/alarm_lifecycle_service.dart';
import '../../../../services/alarm/alarm_service.dart';

class AlarmRingingScreen extends StatefulWidget {
  const AlarmRingingScreen({super.key, required this.alarm});

  final ActiveAlarm alarm;

  @override
  State<AlarmRingingScreen> createState() => _AlarmRingingScreenState();
}

class _AlarmRingingScreenState extends State<AlarmRingingScreen> {
  bool _busy = false;
  bool _allowPop = false;
  int? _resolvedSnoozeMinutes;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final details = await AlarmLifecycleService.instance.resolve(widget.alarm);
    if (!mounted) return;
    setState(() => _resolvedSnoozeMinutes = details.snoozeMinutes);
  }

  String get _typeLabel {
    final payload = widget.alarm.payload;
    if (payload?.startsWith('alarm:event:') ?? false) return 'Evento';
    if (payload?.startsWith('alarm:alert:') ?? false) return 'Alerta';
    return 'Alarma';
  }

  IconData get _typeIcon {
    final payload = widget.alarm.payload;
    if (payload?.startsWith('alarm:event:') ?? false) {
      return Icons.event_rounded;
    }
    if (payload?.startsWith('alarm:alert:') ?? false) {
      return Icons.notifications_active_rounded;
    }
    return Icons.alarm_rounded;
  }

  int get _effectiveSnoozeMinutes => _resolvedSnoozeMinutes ?? 0;

  bool get _canSnooze => _effectiveSnoozeMinutes > 0;

  Future<void> _stop() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AlarmLifecycleService.instance.stop(widget.alarm);
      if (!mounted) return;
      _allowPop = true;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo detener la alarma.')),
      );
    }
  }

  Future<void> _snooze() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AlarmLifecycleService.instance.snooze(widget.alarm);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      _allowPop = true;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Alarma pospuesta $_effectiveSnoozeMinutes minutos.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo posponer la alarma.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return PopScope(
      canPop: _allowPop,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _typeIcon,
                      size: 56,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Chip(
                    avatar: const Icon(Icons.alarm_on_rounded, size: 18),
                    label: const Text('Alarma activa'),
                    backgroundColor: colorScheme.secondaryContainer,
                    labelStyle: TextStyle(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _typeLabel,
                    style: textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.alarm.title,
                    textAlign: TextAlign.center,
                    style: textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.alarm.body,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 36),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _busy ? null : _stop,
                      icon: const Icon(Icons.stop_rounded),
                      label: const Text('Detener'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_canSnooze)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _snooze,
                        icon: const Icon(Icons.snooze_rounded),
                        label: Text('Posponer $_effectiveSnoozeMinutes min'),
                      ),
                    ),
                  if (_busy) ...[
                    const SizedBox(height: 20),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
