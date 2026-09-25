import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/agenda/agenda_controller.dart';
import '../../../application/care/care_controller.dart';
import '../../../domain/agenda/models.dart';
import '../../../domain/agenda/quando.dart';
import '../../../domain/care/phase.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/campo.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/press_linha.dart';

class HorariosScreen extends ConsumerStatefulWidget {
  const HorariosScreen({super.key, required this.fase});

  final CareEscolhendoHorario fase;

  @override
  ConsumerState<HorariosScreen> createState() => _HorariosScreenState();
}

class _HorariosScreenState extends ConsumerState<HorariosScreen> {
  final _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(agendaControllerProvider.notifier)
          .carregarHorarios(widget.fase.profissionalId),
    );
  }

  @override
  void dispose() {
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _reservar(Horario slot) async {
    final ok = await ref
        .read(agendaControllerProvider.notifier)
        .reservar(
          profissionalId: widget.fase.profissionalId,
          horario: slot,
          sessaoId: ref.read(careControllerProvider).sessaoId,
        );
    if (ok && mounted) context.go('/consultas');
  }

  Future<void> _confirmarCodigo() async {
    final ok = await ref
        .read(agendaControllerProvider.notifier)
        .confirmarCodigo(_codigo.text);
    if (ok && mounted) context.go('/consultas');
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(agendaControllerProvider);
    final fase = widget.fase;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: agenda.reservando
                    ? null
                    : () => ref
                          .read(careControllerProvider.notifier)
                          .voltarAosProfissionais(),
                icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                color: CheckmeColors.navy,
              ),
              Text('Horários', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                Text(
                  fase.especialidade.isEmpty
                      ? fase.nome
                      : '${fase.nome} · ${fase.especialidade}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                if (agenda.loading && agenda.horarios.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(
                        color: CheckmeColors.navy,
                      ),
                    ),
                  )
                else if (agenda.horarios.isEmpty && !agenda.pedindoCodigo)
                  Text(
                    agenda.errorMessage ?? 'Nenhum horário aberto agora.',
                    style: TextStyle(
                      color: agenda.errorCode == null
                          ? CheckmeColors.textoSecundario
                          : CheckmeColors.alerta,
                    ),
                  )
                else
                  for (var i = 0; i < agenda.horarios.length; i++) ...[
                    Cascata(
                      index: i,
                      child: PressLinha(
                        onTap: agenda.reservando
                            ? null
                            : () => _reservar(agenda.horarios[i]),
                        child: Cartao(
                          animate: false,
                          child: Text(
                            formatarQuando(agenda.horarios[i].startsAt),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                if (agenda.errorMessage != null &&
                    agenda.horarios.isNotEmpty &&
                    !agenda.pedindoCodigo) ...[
                  const SizedBox(height: 8),
                  Text(
                    agenda.errorMessage!,
                    style: const TextStyle(
                      color: CheckmeColors.alerta,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (agenda.pedindoCodigo) ...[
                  const SizedBox(height: 8),
                  Text(
                    agenda.errorMessage ??
                        'Confirme seu e-mail para continuar.',
                    style: TextStyle(
                      color: agenda.errorCode == null
                          ? CheckmeColors.textoSecundario
                          : CheckmeColors.alerta,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Campo(
                    controller: _codigo,
                    hint: 'Código do e-mail',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Botao(
                    titulo: agenda.reservando ? 'Aguarde…' : 'Confirmar código',
                    onPressed: agenda.reservando ? null : _confirmarCodigo,
                  ),
                  Botao(
                    titulo: 'Reenviar código',
                    variante: BotaoVariante.terciario,
                    onPressed: agenda.reservando
                        ? null
                        : () => ref
                              .read(agendaControllerProvider.notifier)
                              .reenviarCodigo(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
