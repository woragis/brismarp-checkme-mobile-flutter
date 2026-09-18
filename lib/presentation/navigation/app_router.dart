import 'package:go_router/go_router.dart';

import '../screens/conta/conta_placeholder_screen.dart';
import '../screens/cuidar/cuidar_screen.dart';
import '../screens/em_breve_screen.dart';
import 'app_shell.dart';

GoRouter createRouter() {
  return GoRouter(
    initialLocation: '/cuidar',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cuidar',
                builder: (context, state) => const CuidarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consultas',
                builder: (context, state) => const EmBreveScreen(
                  titulo: 'Consultas',
                  texto:
                      'Profissionais, horários e a sala de video entram no próximo recorte. A orientação continua na aba Cuidar.',
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conta',
                builder: (context, state) => const ContaPlaceholderScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
