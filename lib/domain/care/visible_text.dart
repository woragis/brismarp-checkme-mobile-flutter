import 'dart:convert';

/// Patient-facing text from an orientation response.
String visibleOrientationText(String? raw) {
  final text = (raw ?? '').trim();
  if (text.isEmpty || !text.startsWith('{')) return text;
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      final message = decoded['mensagem'];
      if (message is String && message.trim().isNotEmpty) {
        return visibleOrientationText(message);
      }
    }
  } catch (_) {
    return text;
  }
  return '';
}
