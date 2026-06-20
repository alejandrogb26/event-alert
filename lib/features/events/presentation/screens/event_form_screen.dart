import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../alerts/domain/models/app_alarm_config.dart';
import '../../../alerts/domain/models/app_notification_config.dart';
import '../../domain/models/calendar_event.dart';
import '../providers/events_provider.dart';
import '../../../../../services/permissions/permission_service.dart';

// ─────────────────────────────────────────────────────────────────
// Opciones predefinidas
// ─────────────────────────────────────────────────────────────────

// null = sin duración definida
const _durationOptions = [null, 15, 30, 60, 120];

// 1440 = 1 día antes (solo disponible en eventos, no en alertas)
const _minutesBeforeOptions = [0, 5, 10, 15, 30, 60, 120, 1440];

const _snoozeOptions = [0, 5, 10, 15, 20, 30];

// ─────────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────────

class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.event, this.initialDate});

  /// null → modo creación. non-null → modo edición.
  final CalendarEvent? event;

  /// Fecha pre-seleccionada al crear desde el calendario (ignorada en edición).
  final DateTime? initialDate;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;

  // Fecha y hora en hora local (se convierte a UTC al guardar)
  late DateTime _localDate;
  late TimeOfDay _localTime;

  // Duración en minutos; null = sin duración
  late int? _durationMinutes;

  late bool _notifEnabled;
  late int _minutesBefore;

  late bool _alarmEnabled;
  late bool _alarmFullScreen;
  late int _snoozeMinutes;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;

    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _descCtrl = TextEditingController(text: e?.description ?? '');

    if (e != null) {
      // Edición: usa la fecha/hora local del evento existente
      final local = e.startDateTime.toLocal();
      _localDate = DateTime(local.year, local.month, local.day);
      _localTime = TimeOfDay(hour: local.hour, minute: local.minute);
      _durationMinutes = e.duration?.inMinutes;
    } else {
      // Creación: usa initialDate (del calendario) o hoy
      final base = widget.initialDate ?? DateTime.now();
      _localDate = DateTime(base.year, base.month, base.day);
      _localTime = TimeOfDay.now();
      _durationMinutes = null;
    }

    _notifEnabled = e?.notificationConfig.enabled ?? true;
    final savedMinutes = e?.notificationConfig.minutesBefore ?? 0;
    _minutesBefore =
        _minutesBeforeOptions.contains(savedMinutes) ? savedMinutes : 0;

    _alarmEnabled = e?.alarmConfig.enabled ?? false;
    _alarmFullScreen = e?.alarmConfig.fullScreen ?? false;
    final savedSnooze = e?.alarmConfig.snoozeMinutes ?? 5;
    _snoozeMinutes = _snoozeOptions.contains(savedSnooze) ? savedSnooze : 5;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ─────────────────────────────────────────────────

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _localDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Selecciona la fecha',
    );
    if (picked != null) setState(() => _localDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _localTime,
      helpText: 'Selecciona la hora',
    );
    if (picked != null) setState(() => _localTime = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Combina fecha y hora locales → convierte a UTC para persistencia
    final localDateTime = DateTime(
      _localDate.year,
      _localDate.month,
      _localDate.day,
      _localTime.hour,
      _localTime.minute,
    );
    final utcDateTime = localDateTime.toUtc();

    final event = CalendarEvent(
      id: widget.event?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      startDateTime: utcDateTime,
      duration: _durationMinutes != null
          ? Duration(minutes: _durationMinutes!)
          : null,
      notificationConfig: AppNotificationConfig(
        enabled: _notifEnabled,
        minutesBefore: _minutesBefore,
      ),
      alarmConfig: AppAlarmConfig(
        enabled: _alarmEnabled,
        fullScreen: _alarmFullScreen,
        snoozeMinutes: _snoozeMinutes,
      ),
      createdAt: widget.event?.createdAt ?? DateTime.now().toUtc(),
    );

    // Solicitar permiso de notificaciones antes de guardar (si están activas).
    // Si ya está concedido, la llamada es instantánea sin mostrar ningún diálogo.
    bool notifPermGranted = true;
    if (_notifEnabled) {
      final permStatus =
          await PermissionService.instance.requestNotificationPermission();
      notifPermGranted = permStatus == NotificationPermissionStatus.granted;
    }

    final notifier = ref.read(eventsNotifierProvider.notifier);
    if (_isEdit) {
      await notifier.editEvent(event);
    } else {
      await notifier.createEvent(event);
    }

    if (!notifPermGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El evento se ha guardado, pero las notificaciones están desactivadas.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
    }

    if (mounted) Navigator.pop(context);
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Editar evento' : 'Nuevo evento'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          children: [
            // ── Información básica ───────────────────────────────
            _SectionHeader(label: 'Información'),
            _buildTitleField(),
            const SizedBox(height: 12),
            _buildDescriptionField(),

            // ── Fecha y hora ─────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Fecha y hora'),
            _buildDateTile(),
            _buildTimeTile(),

            // ── Duración ─────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Duración'),
            _buildDurationDropdown(),

            // ── Notificación ─────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Notificación'),
            _buildNotificationSection(),

            // ── Alarma ──────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Alarma'),
            _buildAlarmSection(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ── Campos individuales ──────────────────────────────────────

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleCtrl,
      decoration: const InputDecoration(
        labelText: 'Título *',
        hintText: 'Ej: Reunión de equipo',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      validator: (v) =>
          (v == null || v.trim().isEmpty) ? 'El título es obligatorio.' : null,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descCtrl,
      decoration: const InputDecoration(
        labelText: 'Descripción (opcional)',
        border: OutlineInputBorder(),
      ),
      textCapitalization: TextCapitalization.sentences,
      maxLines: 2,
    );
  }

  Widget _buildDateTile() {
    final cs = Theme.of(context).colorScheme;
    final dateStr = DateFormat('EEE, d MMM yyyy', 'es_ES').format(_localDate);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.calendar_today_rounded),
      title: const Text('Fecha'),
      trailing: TextButton(
        onPressed: _pickDate,
        child: Text(
          dateStr,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
              ),
        ),
      ),
    );
  }

  Widget _buildTimeTile() {
    final cs = Theme.of(context).colorScheme;
    final label =
        '${_localTime.hour.toString().padLeft(2, '0')}:${_localTime.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time_rounded),
      title: const Text('Hora'),
      trailing: TextButton(
        onPressed: _pickTime,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: cs.primary,
              ),
        ),
      ),
    );
  }

  Widget _buildDurationDropdown() {
    return DropdownButtonFormField<int?>(
      initialValue: _durationMinutes,
      decoration: const InputDecoration(
        labelText: 'Duración del evento',
        border: OutlineInputBorder(),
      ),
      items: _durationOptions.map((m) {
        final label = switch (m) {
          null => 'Sin duración definida',
          final v when v < 60 => '$v min',
          final v => '${v ~/ 60} h',
        };
        return DropdownMenuItem<int?>(value: m, child: Text(label));
      }).toList(),
      onChanged: (v) => setState(() => _durationMinutes = v),
    );
  }

  Widget _buildNotificationSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Notificación activa'),
          value: _notifEnabled,
          onChanged: (v) => setState(() => _notifEnabled = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_notifEnabled) ...[
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _minutesBefore,
            decoration: const InputDecoration(
              labelText: 'Cuándo notificar',
              border: OutlineInputBorder(),
            ),
            items: _minutesBeforeOptions.map((m) {
              final label = switch (m) {
                0 => 'En el momento',
                1440 => '1 día antes',
                final v when v < 60 => '$v min antes',
                final v => '${v ~/ 60} h antes',
              };
              return DropdownMenuItem(value: m, child: Text(label));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _minutesBefore = v);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAlarmSection() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Alarma sonora'),
          subtitle: const Text('Sonará aunque el teléfono esté en silencio'),
          value: _alarmEnabled,
          onChanged: (v) => setState(() => _alarmEnabled = v),
          contentPadding: EdgeInsets.zero,
        ),
        if (_alarmEnabled) ...[
          SwitchListTile(
            title: const Text('Pantalla completa'),
            subtitle:
                const Text('Muestra una pantalla de alarma al dispararse'),
            value: _alarmFullScreen,
            onChanged: (v) => setState(() => _alarmFullScreen = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            initialValue: _snoozeMinutes,
            decoration: const InputDecoration(
              labelText: 'Posponer',
              border: OutlineInputBorder(),
            ),
            items: _snoozeOptions.map((m) {
              final label = m == 0 ? 'Sin posponer' : '$m minutos';
              return DropdownMenuItem(value: m, child: Text(label));
            }).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _snoozeMinutes = v);
            },
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widget auxiliar de sección
// ─────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
