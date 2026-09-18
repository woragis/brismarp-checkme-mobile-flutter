import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/logo.dart';
import '../em_breve_screen.dart';

class ContaPlaceholderScreen extends ConsumerWidget {
  const ContaPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    if (auth.user == null) {
      return const EmBreveScreen(
        titulo: 'Conta',
        texto:
            'Ficha, família e seus dados entram no próximo recorte. A orientação já funciona na aba Cuidar.',
      );
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Logo(size: 28),
            const Spacer(),
            Text(
              auth.user!.nome,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              auth.user!.email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ficha, dependentes e LGPD entram no recorte Conta. Por agora você já pode sair.',
              style: TextStyle(color: CheckmeColors.textoSecundario),
            ),
            const Spacer(),
            Botao(
              titulo: 'Sair',
              variante: BotaoVariante.secundario,
              onPressed: () => ref.read(authControllerProvider.notifier).sair(),
            ),
          ],
        ),
      ),
    );
  }
}
