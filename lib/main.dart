import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/identity/auth_controller.dart';
import 'infrastructure/api/api_client.dart';
import 'infrastructure/api/api_config.dart';
import 'infrastructure/storage/secure_session_store.dart';
import 'presentation/navigation/app_router.dart';
import 'presentation/theme/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final store = SecureSessionStore();
  final client = ApiClient(config: ApiConfig.resolve());
  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(store),
        apiClientProvider.overrideWithValue(client),
      ],
      child: const CheckmeApp(),
    ),
  );
}

class CheckmeApp extends StatefulWidget {
  const CheckmeApp({super.key});

  @override
  State<CheckmeApp> createState() => _CheckmeAppState();
}

class _CheckmeAppState extends State<CheckmeApp> {
  late final _router = createRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CheckMe',
      debugShowCheckedModeBanner: false,
      theme: checkmeTheme(),
      routerConfig: _router,
    );
  }
}
