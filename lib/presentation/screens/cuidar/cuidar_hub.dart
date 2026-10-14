import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/botao.dart';
import '../../widgets/logo.dart';

class CuidarHub extends ConsumerWidget {
  const CuidarHub({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final ready = ref.watch(apiReadyProvider);
    final visitante = auth.user == null;
    final nome = auth.user?.primeiroNome ?? '';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandHeader(),
            const Spacer(),
            if (!visitante)
              Text(
                'Olá, $nome',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CheckmeColors.care,
                    ),
              ),
            const SizedBox(height: 8),
            Text(
              visitante
                  ? 'Cuidar nunca foi tão fácil'
                  : 'Como podemos cuidar de você hoje?',
              style: Theme.of(context).textTheme.headlineLarge,
            )
                .animate()
                .fadeIn(duration: CheckmeMotion.appear)
                .slideY(begin: 0.06, end: 0, duration: CheckmeMotion.hubToChat),
            const SizedBox(height: 16),
            Text(
              visitante
                  ? 'Conte o que está sentindo. A orientação inicial organiza os sintomas e indica o próximo passo — sem diagnóstico e sem substituir um profissional.'
                  : 'Quando algo não estiver bem, comece pela orientação. Ela indica o próximo passo certo.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            Botao(
              titulo: 'Estou sentindo algo',
              seta: true,
              onPressed: () =>
                  ref.read(careControllerProvider.notifier).comecarOrientacao(),
            ),
            if (visitante) ...[
              const SizedBox(height: 8),
              Botao(
                titulo: 'Já tenho conta',
                variante: BotaoVariante.terciario,
                onPressed: () =>
                    ref.read(careControllerProvider.notifier).abrirSheet(),
              ),
            ],
            const Spacer(),
            ready.when(
              data: (ok) => ok
                  ? const SizedBox.shrink()
                  : Text(
                      'Orientação indisponível no momento. Verifique a API.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: CheckmeColors.alerta,
                          ),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
