import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/agenda/agenda_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../../domain/agenda/models.dart';
import '../../../domain/agenda/quando.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/ir_para_cuidar.dart';
import '../../widgets/logo.dart';
import '../../widgets/press_linha.dart';
import '../../widgets/selo.dart';

const consultasVazias =
    'Você ainda não tem consulta marcada. Reserve um horário a partir da orientação.';

const consultasVisitante =
    'Suas consultas aparecem aqui depois que você entra. Volte para Cuidar e toque em Já tenho conta.';

class ConsultasScreen extends ConsumerStatefulWidget {
  const ConsultasScreen({super.key});

  @override
  ConsumerState<ConsultasScreen> createState() => _ConsultasScreenState();
}

class _ConsultasScreenState extends ConsumerState<ConsultasScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_carregarSeLogado);
  }

  void _carregarSeLogado() {
    if (!mounted) return;
    if (ref.read(authControllerProvider).user != null) {
      ref.read(agendaControllerProvider.notifier).carregarConsultas();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.user != null && prev?.user?.id != next.user?.id) {
        ref.read(agendaControllerProvider.notifier).carregarConsultas();
      }
    });
    final auth = ref.watch(authControllerProvider);
    final agenda = ref.watch(agendaControllerProvider);
    final logado = auth.user != null;
    final vazio = !logado || agenda.consultas.isEmpty;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Logo(size: 28),
            const SizedBox(height: 28),
            Text(
              'Consultas',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            if (logado && agenda.loading && agenda.consultas.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(
                  child: CircularProgressIndicator(color: CheckmeColors.navy),
                ),
              )
            else if (!logado)
              const IrParaCuidar(texto: consultasVisitante)
            else if (vazio)
              Cartao(
                animate: false,
                child: Text(
                  agenda.errorMessage ?? consultasVazias,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )
            else
              Expanded(
                child: ListView(
                  children: [
                    for (var i = 0; i < agenda.consultas.length; i++) ...[
                      Cascata(
                        index: i,
                        child: Cartao(
                          animate: false,
                          child: _cardConsulta(
                            context,
                            agenda,
                            agenda.consultas[i],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (agenda.errorMessage != null)
                      Text(
                        agenda.errorMessage!,
                        style: const TextStyle(
                          color: CheckmeColors.alerta,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cardConsulta(
    BuildContext context,
    AgendaSnapshot agenda,
    Consulta consulta,
  ) {
    final selo = seloDaConsulta(
      status: consulta.status,
      videoStatus: consulta.videoStatus,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _nome(agenda, consulta.profissionalId),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Selo(texto: selo.$1, tom: selo.$2),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          formatarQuando(consulta.startsAt),
          style: Theme.of(context).textTheme.headlineMedium
              ?.copyWith(fontSize: 20),
        ),
        if (consulta.podeEntrar) ...[
          const SizedBox(height: 12),
          Botao(
            titulo: 'Entrar na consulta',
            onPressed: agenda.reservando ? null : () => _entrar(consulta.id),
          ),
        ],
        if (consulta.status != 'cancelada' ||
            _podeEncerrar(agenda, consulta)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            children: [
              if (_podeEncerrar(agenda, consulta))
                Botao(
                  titulo: 'Encerrar',
                  expand: false,
                  variante: BotaoVariante.perigo,
                  onPressed: agenda.reservando
                      ? null
                      : () => ref
                            .read(agendaControllerProvider.notifier)
                            .encerrar(consulta.id),
                ),
              if (consulta.status != 'cancelada') ...[
                Botao(
                  titulo: 'Reagendar',
                  expand: false,
                  variante: BotaoVariante.secundario,
                  onPressed: agenda.reservando
                      ? null
                      : () => ref
                            .read(agendaControllerProvider.notifier)
                            .abrirReagendar(
                              consulta.id,
                              consulta.profissionalId,
                            ),
                ),
                Botao(
                  titulo: 'Cancelar',
                  expand: false,
                  variante: BotaoVariante.terciario,
                  onPressed: agenda.reservando
                      ? null
                      : () => _cancelar(consulta.id),
                ),
              ],
            ],
          ),
        ],
        if (agenda.reagendandoId == consulta.id) ...[
          const SizedBox(height: 8),
          if (agenda.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(color: CheckmeColors.navy),
              ),
            )
          else if (agenda.horarios.isEmpty)
            Text(
              'Nenhum horário aberto agora.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            for (var s = 0; s < agenda.horarios.length; s++)
              Cascata(
                index: s,
                child: PressLinha(
                  onTap: agenda.reservando
                      ? null
                      : () => ref
                            .read(agendaControllerProvider.notifier)
                            .reagendar(consulta.id, agenda.horarios[s]),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      formatarQuando(agenda.horarios[s].startsAt),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
          Botao(
            titulo: 'Fechar horários',
            variante: BotaoVariante.terciario,
            onPressed: agenda.reservando
                ? null
                : () => ref
                      .read(agendaControllerProvider.notifier)
                      .fecharReagendar(),
          ),
        ],
      ],
    );
  }

  bool _podeEncerrar(AgendaSnapshot agenda, Consulta consulta) {
    if (consulta.status == 'cancelada' || consulta.videoStatus == 'encerrada') {
      return false;
    }
    return agenda.salaId == consulta.id || consulta.videoStatus == 'em_curso';
  }

  Future<void> _entrar(String id) async {
    final url = await ref.read(agendaControllerProvider.notifier).entrar(id);
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _cancelar(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar consulta'),
        content: const Text('Esta reserva deixa de valer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar consulta'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(agendaControllerProvider.notifier).cancelar(id);
  }

  String _nome(AgendaSnapshot agenda, String profissionalId) {
    final nome = agenda.nomeDo(profissionalId);
    return nome.isEmpty ? 'Profissional da rede' : nome;
  }
}
