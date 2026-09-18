class FieldError {
  const FieldError({required this.field, required this.code});

  final String field;
  final String code;
}

class ApiException implements Exception {
  const ApiException({
    required this.code,
    required this.message,
    this.status,
    this.fields = const [],
  });

  final String code;
  final String message;
  final int? status;
  final List<FieldError> fields;

  bool get unauthorized => code == 'http.unauthorized' || status == 401;

  @override
  String toString() => 'ApiException($code: $message)';
}
