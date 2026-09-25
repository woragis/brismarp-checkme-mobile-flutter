import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../domain/care/models.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/cartao.dart';
import '../../widgets/check_mark.dart';

class ProximoPassoScreen extends ConsumerWidget {
  const ProximoPassoScreen({
    super.key,
    required this.mensagem,
    required this.status,
    required this.relato,
  });

  final String mensagem;
  final TriageStatus status;
  final String relato;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leve = status == TriageStatus.leve;
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
                    'Você fez o próximo passo certo',
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
                            _Selo(leve: leve),
                          ],
                        ),
                        if (relato.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _Faixa(
                            titulo: 'O que você relatou',
                            texto: relato,
                            cor: CheckmeColors.navy,
                            fundo: CheckmeColors.azulNeve,
                          ),
                        ],
                        const SizedBox(height: 10),
                        _Faixa(
                          titulo: 'Próximo passo',
                          texto: mensagem,
                          cor: CheckmeColors.sucesso,
                          fundo: const Color(0xFFE8F6EE),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Isto organiza o que você descreveu. Não é diagnóstico.',
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
            Botao(
              titulo: 'Ver profissionais',
              seta: true,
              onPressed: () =>
                  ref.read(careControllerProvider.notifier).verProfissionais(),
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
  const _Selo({required this.leve});

  final bool leve;

  @override
  Widget build(BuildContext context) {
    final cor = leve ? CheckmeColors.sucesso : const Color(0xFFE65100);
    final fundo = leve ? const Color(0xFFE8F6EE) : const Color(0xFFFFF4E5);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        leve ? 'Leve' : 'Moderado',
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
