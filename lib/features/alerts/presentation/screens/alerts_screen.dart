import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/confirm_dialog.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/models/alert.dart';
import '../providers/alerts_provider.dart';
import '../widgets/alert_card.dart';
import 'alert_form_screen.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
      ),
      body: alertsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Error al cargar las alertas:\n$e',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (alerts) => alerts.isEmpty
            ? const EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'Sin alertas',
                message:
                    'Toca + para crear tu primera alerta recurrente.',
              )
            : RefreshIndicator(
                onRefresh: () => ref.refresh(alertsNotifierProvider.future),
                child: ListView.builder(
                  // Deja espacio para el FAB al final
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  itemCount: alerts.length,
                  itemBuilder: (ctx, i) {
                    final alert = alerts[i];
                    return AlertCard(
                      alert: alert,
                      onTap: () => _openForm(context, ref, alert: alert),
                      onToggleActive: (_) => ref
                          .read(alertsNotifierProvider.notifier)
                          .toggleActive(alert),
                      onDelete: () => _confirmDelete(context, ref, alert),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'alerts_fab',
        onPressed: () => _openForm(context, ref),
        tooltip: 'Nueva alerta',
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Future<void> _openForm(
    BuildContext context,
    WidgetRef ref, {
    Alert? alert,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AlertFormScreen(alert: alert),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Alert alert,
  ) async {
    final confirmed = await showConfirmDialog(
      context: context,
      title: 'Eliminar alerta',
      message: '¿Quieres eliminar "${alert.title}"?\nEsta acción no se puede deshacer.',
    );
    if (confirmed && context.mounted) {
      await ref.read(alertsNotifierProvider.notifier).delete(alert.id);
    }
  }
}
