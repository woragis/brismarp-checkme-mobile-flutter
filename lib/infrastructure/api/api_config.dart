import 'dart:io';

class ApiConfig {
  const ApiConfig({required this.root});

  final String root;

  String get v1 => '$root/api/v1';

  factory ApiConfig.resolve() {
    const fromEnv = String.fromEnvironment('API_URL', defaultValue: '');
    if (fromEnv.isNotEmpty) {
      return ApiConfig(root: fromEnv.replaceAll(RegExp(r'/$'), ''));
    }
    if (Platform.isAndroid) {
      return const ApiConfig(root: 'http://10.0.2.2:8000');
    }
    return const ApiConfig(root: 'http://localhost:8000');
  }
}
