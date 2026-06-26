import 'package:flutter/material.dart';

import '../../../../core/utils/recurrence_calculator.dart';
import '../../domain/models/alert.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.alert,
    required this.onTap,
    required this.onToggleActive,
    required this.onDelete,
  });

  final Alert alert;

  /// Abre la pantalla de edición.
  final VoidCallback onTap;

  /// Cambia el estado activo/inactivo.
  final ValueChanged<bool> onToggleActive;

  /// Solicita eliminar la alerta (el padre gestiona la confirmación).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final active = alert.isActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: active ? 1 : 0,
        color: active ? cs.surface : cs.surfaceContainer,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Contenido principal ──────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        alert.title,
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: active ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                      // Descripción (si existe)
                      if (alert.description != null &&
                          alert.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          alert.description!,
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 6),
                      // Texto de recurrencia
                      Text(
                        recurrenceText(alert.recurrence, alert.timeMinutes),
                        style: tt.bodySmall?.copyWith(
                          color: active ? cs.primary : cs.outline,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Indicadores de notificación y alarma
                      _FeatureChips(alert: alert),
                    ],
                  ),
                ),
                // ── Controles ────────────────────────────────────
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(value: active, onChanged: onToggleActive),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: cs.error,
                        size: 20,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Fila de chips pequeños que indican si la notificación y la alarma están activas.
class _FeatureChips extends StatelessWidget {
  const _FeatureChips({required this.alert});

  final Alert alert;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final chips = <Widget>[];

    if (alert.notificationConfig.enabled) {
      chips.add(
        _chip(
          context,
          icon: Icons.notifications_rounded,
          label: 'Notificación',
          color: cs.secondary,
          labelStyle: tt,
        ),
      );
    }

    if (alert.alarmConfig.enabled) {
      if (chips.isNotEmpty) chips.add(const SizedBox(width: 6));
      chips.add(
        _chip(
          context,
          icon: Icons.alarm_rounded,
          label: 'Alarma',
          color: cs.tertiary,
          labelStyle: tt,
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: chips);
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required TextTheme labelStyle,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 3),
        Text(label, style: labelStyle.labelSmall?.copyWith(color: color)),
      ],
    );
  }
}
