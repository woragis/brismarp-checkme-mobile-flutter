import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/cartao.dart';
import '../../widgets/check_mark.dart';

class ProximoPassoScreen extends ConsumerWidget {
  const ProximoPassoScreen({
    super.key,
    required this.mensagem,
  });

  final String mensagem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CheckMark(),
            const SizedBox(height: 28),
            Text(
              'Você fez o próximo passo certo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            Cartao(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mensagem,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: CheckmeColors.texto,
                          fontSize: 15,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Isto organiza o que você descreveu. Não é diagnóstico.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Botao(
              titulo: 'Ver profissionais — em breve',
              onPressed: null,
            ),
            const SizedBox(height: 8),
            Botao(
              titulo: 'Nova orientação',
              variante: BotaoVariante.terciario,
              onPressed: () =>
                  ref.read(careControllerProvider.notifier).novaOrientacao(),
            ),
            Botao(
              titulo: 'Voltar',
              variante: BotaoVariante.terciario,
              onPressed: () =>
                  ref.read(careControllerProvider.notifier).voltarAoHub(),
            ),
          ],
        ),
      ),
    );
  }
}
