import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/conta/conta_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import 'porta_screen.dart';
import 'tela_interna.dart';

class ExcluirScreen extends ConsumerWidget {
  const ExcluirScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(authControllerProvider).user == null) {
      return const PortaScreen();
    }
    final conta = ref.watch(contaControllerProvider);
    return TelaInterna(
      titulo: 'Excluir conta',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Text(
            'Isso anonimiza seu nome, e-mail, CPF, telefone e o histórico de orientação. Não dá para desfazer.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (conta.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              conta.errorMessage!,
              style: const TextStyle(color: CheckmeColors.alerta, fontSize: 13),
            ),
          ],
          const SizedBox(height: 16),
          Botao(
            titulo: conta.salvando ? 'Aguarde…' : 'Excluir conta',
            variante: BotaoVariante.perigo,
            onPressed: conta.salvando
                ? null
                : () async {
                    final ok = await ref
                        .read(contaControllerProvider.notifier)
                        .apagar();
                    if (ok && context.mounted) context.go('/cuidar');
                  },
          ),
        ],
      ),
    );
  }
}
