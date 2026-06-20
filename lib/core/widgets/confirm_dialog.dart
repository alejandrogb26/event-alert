import 'package:flutter/material.dart';

/// Muestra un diálogo de confirmación y devuelve true si el usuario acepta.
///
/// Ejemplo:
/// ```dart
/// final ok = await showConfirmDialog(
///   context: context,
///   title: 'Eliminar alerta',
///   message: '¿Quieres eliminar "${alert.title}"?',
/// );
/// if (ok) { ... }
/// ```
Future<bool> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Eliminar',
  String cancelLabel = 'Cancelar',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
            foregroundColor: Theme.of(ctx).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
