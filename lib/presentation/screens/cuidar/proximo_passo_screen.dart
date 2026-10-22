import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../domain/care/models.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/cartao.dart';
import '../../widgets/check_mark.dart';
import '../../widgets/tutorial_button.dart';

class ProximoPassoScreen extends ConsumerWidget {
  const ProximoPassoScreen({
    super.key,
    required this.mensagem,
    required this.status,
  });

  final String mensagem;
  final TriageStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: 24),
                  const Center(child: CheckMark()),
                  const SizedBox(height: 28),
                  Text(
                    'Vamos encontrar o profissional certo',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  Cartao(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Seu próximo passo',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: CheckmeColors.navy,
                                      fontSize: 13,
                                    ),
                              ),
                            ),
                            const _Selo(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _Faixa(
                          titulo: 'Próximo passo',
                          texto: mensagem,
                          cor: CheckmeColors.sucesso,
                          fundo: const Color(0xFFE8F6EE),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Esta é apenas uma sugestão de especialidade. O profissional avaliará suas necessidades durante a consulta.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TutorialAnchor(
              id: 'care-next-step',
              child: Botao(
                titulo: 'Ver profissionais',
                seta: true,
                onPressed: () => ref
                    .read(careControllerProvider.notifier)
                    .verProfissionais(),
              ),
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

class _Selo extends StatelessWidget {
  const _Selo();

  @override
  Widget build(BuildContext context) {
    const cor = CheckmeColors.navy;
    const fundo = CheckmeColors.azulNeve;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Especialidade sugerida',
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Faixa extends StatelessWidget {
  const _Faixa({
    required this.titulo,
    required this.texto,
    required this.cor,
    required this.fundo,
  });

  final String titulo;
  final String texto;
  final Color cor;
  final Color fundo;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cor, width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              color: cor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            texto,
            style: const TextStyle(
              color: CheckmeColors.texto,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
