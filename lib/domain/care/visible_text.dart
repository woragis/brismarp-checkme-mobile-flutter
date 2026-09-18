import 'dart:convert';

/// Patient-facing text from a chat payload. SOAP JSON is not shown on the journey.
String visibleOrientationText(String? raw) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return '';
  if (!t.startsWith('{')) return t;
  try {
    final decoded = jsonDecode(t);
    if (decoded is Map<String, dynamic>) {
      final inner = decoded['mensagem'];
      if (inner is String && inner.trim().isNotEmpty) {
        return visibleOrientationText(inner);
      }
    }
  } catch (_) {
    /* keep raw if it is not JSON */
  }
  return '';
}

bool looksLikeSoapJson(String? raw) {
  final t = (raw ?? '').trim();
  if (!t.startsWith('{')) return false;
  try {
    final decoded = jsonDecode(t);
    if (decoded is! Map) return false;
    return decoded.containsKey('S') ||
        decoded.containsKey('s') ||
        decoded.containsKey('soap') ||
        decoded.containsKey('status') ||
        decoded.containsKey('subjetivo') ||
        decoded.containsKey('mensagem');
  } catch (_) {
    return false;
  }
}
