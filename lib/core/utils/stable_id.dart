/// Hash FNV-1a 32-bit sobre [input].
///
/// Produce el mismo int en cualquier ejecución de la VM, a diferencia de
/// [Object.hashCode], que puede variar entre versiones de Dart.
/// El resultado siempre es positivo y nunca es 0 ni -1.
///
/// - 0 está prohibido por el paquete `alarm`.
/// - -1 es imposible con la máscara `& 0x7FFFFFFF`, pero se documenta
///   para evitar confusión si este código se reutiliza en otros contextos.
///
/// Namespaces recomendados para evitar colisiones entre subsistemas:
/// ```
/// Notificación de evento  : stableId('event:<id>')
/// Notificación de alerta  : stableId('alert:<id>')
/// Alarma de evento        : stableId('alarm:event:<id>')
/// Alarma de alerta        : stableId('alarm:alert:<id>')
/// ```
int stableId(String input) {
  var hash = 0x811c9dc5;
  for (final byte in input.codeUnits) {
    hash ^= byte;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final result = hash & 0x7FFFFFFF;
  // 0 está prohibido por alarm; probabilidad ~1/2^31 pero se trata explícitamente.
  return result == 0 ? 1 : result;
}
