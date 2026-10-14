import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/agenda/agenda_controller.dart';
import '../../../application/care/care_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../../application/planos/planos_controller.dart';
import '../../../domain/agenda/models.dart';
import '../../../domain/agenda/quando.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/botao.dart';
import '../../widgets/cartao.dart';
import '../../widgets/logo.dart';
import '../../widgets/press_linha.dart';

class CuidarHub extends ConsumerStatefulWidget {
  const CuidarHub({super.key});

  @override
  ConsumerState<CuidarHub> createState() => _CuidarHubState();
}

class _CuidarHubState extends ConsumerState<CuidarHub> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_carregarCasa);
  }

  void _carregarCasa() {
    if (!mounted) return;
    if (ref.read(authControllerProvider).user == null) return;
    ref.read(planosControllerProvider.notifier).carregar();
    ref.read(agendaControllerProvider.notifier).carregarConsultas();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (prev, next) {
      if (next.user != null && prev?.user?.id != next.user?.id) {
        _carregarCasa();
      }
    });

    final auth = ref.watch(authControllerProvider);
    final care = ref.watch(careControllerProvider);
    final ready = ref.watch(apiReadyProvider);
    final planos = ref.watch(planosControllerProvider);
    final agenda = ref.watch(agendaControllerProvider);
    final visitante = auth.user == null;
    final nome = auth.user?.primeiroNome ?? '';
    final proxima = visitante ? null : _proximaConsulta(agenda.consultas);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const BrandHeader(),
          const SizedBox(height: 28),
          if (!visitante) ...[
            Text(
              'Olá, $nome',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(color: CheckmeColors.care),
            ),
            const SizedBox(height: 8),
          ],
          Text(
                visitante
                    ? 'Cuidar nunca foi tão fácil'
                    : 'Como podemos cuidar de você hoje?',
                style: Theme.of(context).textTheme.headlineLarge,
              )
              .animate()
              .fadeIn(duration: CheckmeMotion.appear)
              .slideY(begin: 0.06, end: 0, duration: CheckmeMotion.hubToChat),
          if (!visitante && planos.planoAtivo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: CheckmeColors.azulNeve,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  planos.planoAtivo,
                  style: const TextStyle(
                    color: CheckmeColors.navy,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            visitante
                ? 'Conte o que está sentindo. A orientação inicial organiza os sintomas e indica o próximo passo — sem diagnóstico e sem substituir um profissional.'
                : 'Quando algo não estiver bem, comece pela orientação. Ela indica o próximo passo certo.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (care.orientacaoAberta) ...[
            const SizedBox(height: 20),
            PressLinha(
              onTap: () =>
                  ref.read(careControllerProvider.notifier).retomarOrientacao(),
              child: const Cartao(
                animate: false,
                child: Row(
                  children: [
                    Icon(Icons.chat_bubble_outline, color: CheckmeColors.navy),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Continuar orientação',
                        style: TextStyle(
                          color: CheckmeColors.texto,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: CheckmeColors.care),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Botao(
            titulo: 'Estou sentindo algo',
            seta: true,
            onPressed: () {
              final notifier = ref.read(careControllerProvider.notifier);
              if (care.orientacaoAberta) {
                notifier.novaOrientacao();
              } else {
                notifier.comecarOrientacao();
              }
            },
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
          if (proxima != null) ...[
            const SizedBox(height: 20),
            PressLinha(
              onTap: () => context.go('/consultas'),
              child: Cartao(
                animate: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próxima consulta',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _nome(agenda, proxima.profissionalId),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatarQuando(proxima.startsAt),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontSize: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Para consultar',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const _Atalho(
            titulo: 'Especialidades',
            apoio: 'O que a rede atende',
            icone: Icons.medical_services_outlined,
            path: '/cuidar/especialidades',
          ),
          const SizedBox(height: 8),
          const _Atalho(
            titulo: 'Rede credenciada',
            apoio: 'Particular, nosso valor e economia',
            icone: Icons.place_outlined,
            path: '/cuidar/rede',
          ),
          const SizedBox(height: 8),
          const _Atalho(
            titulo: 'FAQ',
            apoio: 'Perguntas frequentes',
            icone: Icons.help_outline,
            path: '/cuidar/faq',
          ),
          const SizedBox(height: 16),
          ready.when(
            data: (ok) => ok
                ? const SizedBox.shrink()
                : Text(
                    'Orientação indisponível no momento. Verifique a API.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: CheckmeColors.alerta),
                  ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

Consulta? _proximaConsulta(List<Consulta> lista) {
  final agora = DateTime.now();
  final quando = proximoFuturo([
    for (final consulta in lista)
      if (consulta.status != 'cancelada') consulta.startsAt,
  ], agora);
  if (quando == null) return null;
  for (final consulta in lista) {
    if (consulta.status == 'cancelada') continue;
    if (consulta.startsAt == quando) return consulta;
  }
  return null;
}

String _nome(AgendaSnapshot agenda, String profissionalId) {
  final nome = agenda.nomeDo(profissionalId);
  return nome.isEmpty ? 'Profissional da rede' : nome;
}

class _Atalho extends StatelessWidget {
  const _Atalho({
    required this.titulo,
    required this.apoio,
    required this.icone,
    required this.path,
  });

  final String titulo;
  final String apoio;
  final IconData icone;
  final String path;

  @override
  Widget build(BuildContext context) {
    return PressLinha(
      onTap: () => context.push(path),
      child: Cartao(
        animate: false,
        child: Row(
          children: [
            Icon(icone, color: CheckmeColors.navy),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: Theme.of(context).textTheme.titleMedium),
                  Text(apoio, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: CheckmeColors.care),
          ],
        ),
      ),
    );
  }
}
