import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/agenda/agenda_controller.dart';
import '../../../application/care/care_controller.dart';
import '../../../domain/agenda/quando.dart';
import '../../theme/colors.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/press_linha.dart';

class ProfissionaisScreen extends ConsumerStatefulWidget {
  const ProfissionaisScreen({super.key});

  @override
  ConsumerState<ProfissionaisScreen> createState() =>
      _ProfissionaisScreenState();
}

class _ProfissionaisScreenState extends ConsumerState<ProfissionaisScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(agendaControllerProvider.notifier).carregarProfissionais(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(agendaControllerProvider);
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () =>
                    ref.read(careControllerProvider.notifier).voltarAoPasso(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: CheckmeColors.navy,
              ),
              Text(
                'Profissionais',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Text(
                  'Escolha quem continua o cuidado. A orientação segue com a consulta.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (agenda.loading && agenda.profissionais.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: CheckmeColors.navy,
                      ),
                    ),
                  )
                else if (agenda.errorMessage != null &&
                    agenda.profissionais.isEmpty)
                  Text(
                    agenda.errorMessage!,
                    style: const TextStyle(color: CheckmeColors.alerta),
                  )
                else if (agenda.profissionais.isEmpty)
                  Text(
                    'Nenhum profissional disponível agora.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  for (var i = 0; i < agenda.profissionais.length; i++) ...[
                    Cascata(
                      index: i,
                      child: PressLinha(
                        onTap: () {
                          final pro = agenda.profissionais[i];
                          ref
                              .read(careControllerProvider.notifier)
                              .escolherHorario(
                                profissionalId: pro.id,
                                nome: pro.nome,
                                especialidade: pro.especialidade,
                              );
                        },
                        child: Cartao(
                          animate: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                agenda.profissionais[i].nome,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              if (agenda
                                  .profissionais[i]
                                  .especialidade
                                  .isNotEmpty)
                                Text(
                                  agenda.profissionais[i].especialidade,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              if (agenda.profissionais[i].proximo != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  formatarQuando(
                                    agenda.profissionais[i].proximo!,
                                  ),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: CheckmeColors.care,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
