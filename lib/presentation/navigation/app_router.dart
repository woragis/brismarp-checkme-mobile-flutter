import 'package:go_router/go_router.dart';

import '../screens/consultas/consultas_screen.dart';
import '../screens/conta/conteudo_screen.dart';
import '../screens/conta/conta_menu_screen.dart';
import '../screens/conta/dados_screen.dart';
import '../screens/conta/excluir_screen.dart';
import '../screens/conta/familia_screen.dart';
import '../screens/conta/ficha_screen.dart';
import '../screens/conta/porta_screen.dart';
import '../screens/cuidar/cuidar_screen.dart';
import '../screens/planos/planos_screen.dart';
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
                routes: [
                  GoRoute(
                    path: 'especialidades',
                    builder: (context, state) =>
                        const ConteudoScreen(tipo: ConteudoTipo.especialidades),
                  ),
                  GoRoute(
                    path: 'rede',
                    builder: (context, state) =>
                        const ConteudoScreen(tipo: ConteudoTipo.rede),
                  ),
                  GoRoute(
                    path: 'faq',
                    builder: (context, state) =>
                        const ConteudoScreen(tipo: ConteudoTipo.faq),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/consultas',
                builder: (context, state) => const ConsultasScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/planos',
                builder: (context, state) => const PlanosScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/conta',
                builder: (context, state) => const ContaMenuScreen(),
                routes: [
                  GoRoute(
                    path: 'porta',
                    builder: (context, state) => const PortaScreen(),
                  ),
                  GoRoute(
                    path: 'ficha',
                    builder: (context, state) => const FichaScreen(),
                  ),
                  GoRoute(
                    path: 'familia',
                    builder: (context, state) => const FamiliaScreen(),
                  ),
                  GoRoute(
                    path: 'dados',
                    builder: (context, state) => const DadosScreen(),
                  ),
                  GoRoute(
                    path: 'excluir',
                    builder: (context, state) => const ExcluirScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
