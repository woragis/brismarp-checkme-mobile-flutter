import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:checkme/application/identity/auth_controller.dart';
import 'package:checkme/infrastructure/api/api_client.dart';
import 'package:checkme/infrastructure/api/api_config.dart';
import 'package:checkme/infrastructure/storage/session_store.dart';
import 'package:checkme/presentation/navigation/app_router.dart';
import 'package:checkme/presentation/screens/consultas/consultas_screen.dart';
import 'package:checkme/presentation/theme/theme.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('hub visitor shows care CTA and placeholders stay honest', (
    tester,
  ) async {
    final store = MemorySessionStore();
    final client = ApiClient(
      config: const ApiConfig(root: 'http://127.0.0.1:9'),
    );
    final router = createRouter();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionStoreProvider.overrideWithValue(store),
          apiClientProvider.overrideWithValue(client),
        ],
        child: MaterialApp.router(theme: checkmeTheme(), routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Cuidar nunca foi tão fácil'), findsOneWidget);
    expect(find.text('Estou sentindo algo'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Especialidades'), 200);
    expect(find.text('Especialidades'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rede credenciada'), 200);
    expect(find.text('Rede credenciada'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('FAQ'), 200);
    expect(find.text('FAQ'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Estou sentindo algo'), 200);
    await tester.tap(find.text('Estou sentindo algo'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Orientação inicial'), findsOneWidget);
    expect(
      find.textContaining('Pode me contar o que você está sentindo'),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'dor de cabeça');
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Continuar orientação'), findsOneWidget);
    expect(find.text('Cuidar nunca foi tão fácil'), findsOneWidget);

    await tester.tap(find.text('Continuar orientação'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Orientação inicial'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'dor de cabeça',
    );

    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Continue a orientação'), findsOneWidget);
    expect(find.text('Preciso de emergência agora'), findsOneWidget);

    await tester.tap(find.text('Consultas'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text(consultasVisitante), findsOneWidget);
    expect(find.text('Ir para Cuidar'), findsOneWidget);

    await tester.tap(find.text('Conta'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Especialidades'), findsNothing);
    expect(find.text('Ficha'), findsOneWidget);
  });
}
