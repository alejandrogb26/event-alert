import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/alert.dart';
import '../../domain/models/app_alarm_config.dart';
import '../../domain/models/app_notification_config.dart';
import '../../domain/models/recurrence_rule.dart';
import '../providers/alerts_provider.dart';
import '../../../../../services/permissions/permission_service.dart';

// ─────────────────────────────────────────────────────────────────
// Opciones predefinidas
// ─────────────────────────────────────────────────────────────────

const _minutesBeforeOptions = [0, 5, 10, 15, 30, 60, 120];
const _snoozeOptions = [0, 5, 10, 15, 20, 30];

const _weekdayLabels = {1: 'L', 2: 'M', 3: 'X', 4: 'J', 5: 'V', 6: 'S', 7: 'D'};

const _weekdayFullNames = {
  1: 'Lunes',
  2: 'Martes',
  3: 'Miércoles',
  4: 'Jueves',
  5: 'Viernes',
  6: 'Sábado',
  7: 'Domingo',
};

// ─────────────────────────────────────────────────────────────────
// Conversión TimeOfDay ↔ timeMinutes
// ─────────────────────────────────────────────────────────────────

TimeOfDay _minutesToTimeOfDay(int minutes) =>
    TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);

int _timeOfDayToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

// ─────────────────────────────────────────────────────────────────
// Pantalla
// ─────────────────────────────────────────────────────────────────

class AlertFormScreen extends ConsumerStatefulWidget {
  const AlertFormScreen({super.key, this.alert});

  /// null → modo creación. non-null → modo edición.
  final Alert? alert;

  @override
  ConsumerState<AlertFormScreen> createState() => _AlertFormScreenState();
}

class _AlertFormScreenState extends ConsumerState<AlertFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _intervalCtrl;
  late final TextEditingController _dayOfMonthCtrl;

  // Estado del formulario
  late TimeOfDay _time;
  late RecurrenceType _recurrenceType;
  late List<int> _selectedWeekdays;
  DateTime? _endDate;

  late bool _notifEnabled;
  late int _minutesBefore;

  late bool _alarmEnabled;
  late int _snoozeMinutes;

  late bool _isActive;

  bool get _isEdit => widget.alert != null;

  @override
  void initState() {
    super.initState();
    final a = widget.alert;

    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _descCtrl = TextEditingController(text: a?.description ?? '');
    _intervalCtrl = TextEditingController(
      text: (a?.recurrence.interval ?? 1).toString(),
    );
    _dayOfMonthCtrl = TextEditingController(
      text: (a?.recurrence.dayOfMonth ?? 1).toString(),
    );

    _time = a != null ? _minutesToTimeOfDay(a.timeMinutes) : TimeOfDay.now();
    _recurrenceType = a?.recurrence.type ?? RecurrenceType.daily;

    // Weekdays: si viene de edición, copia la lista; si no, usa el día actual
    _selectedWeekdays = (a?.recurrence.weekdays != null)
        ? List<int>.from(a!.recurrence.weekdays!)
        : [DateTime.now().weekday];

    _endDate = a?.recurrence.endDate;

    _notifEnabled = a?.notificationConfig.enabled ?? true;
    // Asegura que el valor está en la lista de opciones; si no, cae a 0
    final savedMinutes = a?.notificationConfig.minutesBefore ?? 0;
    _minutesBefore = _minutesBeforeOptions.contains(savedMinutes)
        ? savedMinutes
        : 0;

    _alarmEnabled = a?.alarmConfig.enabled ?? false;
    final savedSnooze = a?.alarmConfig.snoozeMinutes ?? 5;
    _snoozeMinutes = _snoozeOptions.contains(savedSnooze) ? savedSnooze : 5;

    _isActive = a?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _intervalCtrl.dispose();
    _dayOfMonthCtrl.dispose();
    super.dispose();
  }

  // ── Acciones ─────────────────────────────────────────────────

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Selecciona la hora',
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      helpText: 'Fecha límite de la alerta',
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  void _clearEndDate() => setState(() => _endDate = null);

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación extra: al menos un día seleccionado en modo semanal
    if (_recurrenceType == RecurrenceType.weekly && _selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día de la semana.'),
        ),
      );
      return;
    }

    final interval = (int.tryParse(_intervalCtrl.text) ?? 1).clamp(1, 99);
    final dayOfMonth = (int.tryParse(_dayOfMonthCtrl.text) ?? 1).clamp(1, 31);

    final recurrence = RecurrenceRule(
      type: _recurrenceType,
      interval: interval,
      weekdays: _recurrenceType == RecurrenceType.weekly
          ? List<int>.from(_selectedWeekdays)
          : null,
      dayOfMonth: _recurrenceType == RecurrenceType.monthly ? dayOfMonth : null,
      endDate: _endDate,
    );

    final alert = Alert(
      id: widget.alert?.id ?? const Uuid().v4(),
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      timeMinutes: _timeOfDayToMinutes(_time),
      recurrence: recurrence,
      notificationConfig: AppNotificationConfig(
        enabled: _notifEnabled,
        minutesBefore: _minutesBefore,
      ),
      alarmConfig: AppAlarmConfig(
        enabled: _alarmEnabled,
        fullScreen: false,
        snoozeMinutes: _snoozeMinutes,
      ),
      isActive: _isActive,
      createdAt: widget.alert?.createdAt ?? DateTime.now().toUtc(),
      lastTriggeredAt: widget.alert?.lastTriggeredAt,
    );

    // Solicitar permiso de notificaciones antes de guardar (si están activas).
    // Si ya está concedido, la llamada es instantánea sin mostrar ningún diálogo.
    bool notifPermGranted = true;
    if (_notifEnabled) {
      final permStatus = await PermissionService.instance
          .requestNotificationPermission();
      notifPermGranted = permStatus == NotificationPermissionStatus.granted;
    }

    final notifier = ref.read(alertsNotifierProvider.notifier);
    if (_isEdit) {
      await notifier.edit(alert);
    } else {
      await notifier.create(alert);
    }

    if (!notifPermGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La alerta se ha guardado, pero las notificaciones están desactivadas.',
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
        title: Text(_isEdit ? 'Editar alerta' : 'Nueva alerta'),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
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

            // ── Hora ────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Hora'),
            _buildTimeTile(),

            // ── Repetición ──────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Repetición'),
            _buildRecurrenceTypeDropdown(),
            const SizedBox(height: 12),
            _buildIntervalField(),
            if (_recurrenceType == RecurrenceType.weekly) ...[
              const SizedBox(height: 12),
              _buildWeekdaySelector(),
            ],
            if (_recurrenceType == RecurrenceType.monthly) ...[
              const SizedBox(height: 12),
              _buildDayOfMonthField(),
            ],
            const SizedBox(height: 12),
            _buildEndDateTile(),

            // ── Notificación ─────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Notificación'),
            _buildNotificationSection(),

            // ── Alarma ──────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Alarma'),
            _buildAlarmSection(),

            // ── Estado ──────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionHeader(label: 'Estado'),
            SwitchListTile(
              title: const Text('Alerta activa'),
              subtitle: Text(
                _isActive
                    ? 'La alerta disparará cuando corresponda.'
                    : 'La alerta está desactivada y no disparará.',
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              contentPadding: EdgeInsets.zero,
            ),

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

  Widget _buildTimeTile() {
    final label =
        '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}';
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.access_time_rounded),
      title: const Text('Hora de la alerta'),
      trailing: TextButton(
        onPressed: _pickTime,
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildRecurrenceTypeDropdown() {
    return DropdownButtonFormField<RecurrenceType>(
      initialValue: _recurrenceType,
      decoration: const InputDecoration(
        labelText: 'Tipo de repetición',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: RecurrenceType.daily, child: Text('Diaria')),
        DropdownMenuItem(value: RecurrenceType.weekly, child: Text('Semanal')),
        DropdownMenuItem(value: RecurrenceType.monthly, child: Text('Mensual')),
        DropdownMenuItem(
          value: RecurrenceType.monthlyFirst,
          child: Text('Primer día del mes'),
        ),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _recurrenceType = v;
          // Si se cambia a semanal y no hay días, añadir el día actual
          if (v == RecurrenceType.weekly && _selectedWeekdays.isEmpty) {
            _selectedWeekdays = [DateTime.now().weekday];
          }
        });
      },
    );
  }

  Widget _buildIntervalField() {
    final suffix = switch (_recurrenceType) {
      RecurrenceType.daily => 'día(s)',
      RecurrenceType.weekly => 'semana(s)',
      RecurrenceType.monthly || RecurrenceType.monthlyFirst => 'mes(es)',
    };

    return TextFormField(
      controller: _intervalCtrl,
      decoration: InputDecoration(
        labelText: 'Intervalo',
        suffixText: suffix,
        border: const OutlineInputBorder(),
        helperText: 'Repite cada N $suffix',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < 1) return 'Introduce un número >= 1.';
        return null;
      },
    );
  }

  Widget _buildWeekdaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Días de la semana',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          children: [1, 2, 3, 4, 5, 6, 7].map((day) {
            final selected = _selectedWeekdays.contains(day);
            return FilterChip(
              label: Text(_weekdayLabels[day]!),
              tooltip: _weekdayFullNames[day],
              selected: selected,
              onSelected: (on) {
                setState(() {
                  if (on) {
                    _selectedWeekdays.add(day);
                    _selectedWeekdays.sort();
                  } else {
                    _selectedWeekdays.remove(day);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDayOfMonthField() {
    return TextFormField(
      controller: _dayOfMonthCtrl,
      decoration: const InputDecoration(
        labelText: 'Día del mes',
        suffixText: 'del mes',
        border: OutlineInputBorder(),
        helperText:
            'Entre 1 y 31 (se ajusta al último día si el mes es más corto)',
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < 1 || n > 31) {
          return 'Introduce un día entre 1 y 31.';
        }
        return null;
      },
    );
  }

  Widget _buildEndDateTile() {
    final cs = Theme.of(context).colorScheme;
    final label = _endDate == null
        ? 'Sin fecha límite'
        : '${_endDate!.day.toString().padLeft(2, '0')}/'
              '${_endDate!.month.toString().padLeft(2, '0')}/'
              '${_endDate!.year}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event_busy_rounded),
      title: const Text('Fecha límite (opcional)'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _pickEndDate,
            child: Text(label, style: TextStyle(color: cs.primary)),
          ),
          if (_endDate != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _clearEndDate,
              iconSize: 18,
              tooltip: 'Quitar fecha límite',
            ),
        ],
      ),
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
