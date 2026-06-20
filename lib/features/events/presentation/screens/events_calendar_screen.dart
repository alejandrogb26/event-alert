import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../domain/models/calendar_event.dart';
import '../providers/events_provider.dart';
import '../widgets/event_card.dart';
import 'event_form_screen.dart';

class EventsCalendarScreen extends ConsumerStatefulWidget {
  const EventsCalendarScreen({super.key});

  @override
  ConsumerState<EventsCalendarScreen> createState() =>
      _EventsCalendarScreenState();
}

class _EventsCalendarScreenState extends ConsumerState<EventsCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // ───────────────────────────────────────────
  // Navegación a formulario
  // ───────────────────────────────────────────

  Future<void> _openForm(BuildContext context, {CalendarEvent? event}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EventFormScreen(
          event: event,
          initialDate: event == null ? _selectedDay : null,
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // Confirmación de eliminación
  // ───────────────────────────────────────────

  Future<void> _confirmDelete(
    BuildContext context,
    CalendarEvent event,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar evento',
      message: '¿Eliminar "${event.title}"? Esta acción no se puede deshacer.',
    );
    if (confirmed && context.mounted) {
      await ref.read(eventsNotifierProvider.notifier).deleteEvent(event.id);
    }
  }

  // ───────────────────────────────────────────
  // Build
  // ───────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Eventos')),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (allEvents) {
          final selectedEvents = eventsForDay(allEvents, _selectedDay);

          return Column(
            children: [
              // ─── Calendario ───────────────────────────────
              TableCalendar<CalendarEvent>(
                locale: 'es_ES',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
                calendarFormat: _calendarFormat,
                startingDayOfWeek: StartingDayOfWeek.monday,
                eventLoader: (day) => eventsForDay(allEvents, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: colorScheme.primary.withAlpha(80),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: colorScheme.tertiary,
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outline),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  formatButtonTextStyle: textTheme.labelSmall!,
                ),
              ),

              const Divider(height: 1),

              // ─── Lista de eventos del día seleccionado ────
              Expanded(
                child: selectedEvents.isEmpty
                    ? _EmptyDayState(
                        day: _selectedDay,
                        onAdd: () => _openForm(context),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: selectedEvents.length,
                        itemBuilder: (_, index) {
                          final event = selectedEvents[index];
                          return EventCard(
                            event: event,
                            onTap: () => _openForm(context, event: event),
                            onDelete: () => _confirmDelete(context, event),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'events_fab',
        onPressed: () => _openForm(context),
        tooltip: 'Nuevo evento',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Widget auxiliar: día sin eventos
// ─────────────────────────────────────────────────────────────────

class _EmptyDayState extends StatelessWidget {
  const _EmptyDayState({required this.day, required this.onAdd});

  final DateTime day;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isToday = isSameDay(day, DateTime.now());
    final label = isToday ? 'Hoy no hay eventos' : 'Sin eventos este día';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available_rounded,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Añadir evento'),
          ),
        ],
      ),
    );
  }
}
