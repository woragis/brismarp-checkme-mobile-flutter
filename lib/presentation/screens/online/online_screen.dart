import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/agenda/agenda_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../../domain/agenda/models.dart';
import '../../../domain/agenda/quando.dart';
import '../../../infrastructure/api/checkme_api.dart';
import '../../theme/colors.dart';
import '../../widgets/tutorial_button.dart';

class OnlineScreen extends ConsumerStatefulWidget {
  const OnlineScreen({super.key});

  @override
  ConsumerState<OnlineScreen> createState() => _OnlineScreenState();
}

class _OnlineScreenState extends ConsumerState<OnlineScreen> {
  List<String> _especialidades = const [];
  String? _selecionada;
  SugestaoConsulta? _sugestao;
  String? _erro;
  bool _carregandoEspecialidades = true;
  bool _buscando = false;
  bool _codigo = false;
  final _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(_carregarEspecialidades);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  Future<void> _carregarEspecialidades() async {
    try {
      final items = await ref.read(checkmeApiProvider).especialidades();
      if (!mounted) return;
      setState(() {
        _especialidades = items;
        _selecionada = items.isEmpty ? null : items.first;
        _carregandoEspecialidades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _carregandoEspecialidades = false;
        _erro = 'Não foi possível carregar as especialidades.';
      });
    }
  }

  Future<void> _buscar() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;
    final especialidade = _selecionada;
    if (especialidade == null) return;
    setState(() {
      _buscando = true;
      _erro = null;
      _codigo = false;
      _sugestao = null;
    });
    try {
      final result = await ref
          .read(checkmeApiProvider)
          .sugerirProfissional(especialidade);
      if (!mounted) return;
      setState(() {
        _sugestao = result;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _buscando = false;
        _erro = 'Não foi possível buscar agora. Tente novamente.';
      });
    }
  }

  Future<void> _confirmar() async {
    final option = _sugestao;
    if (option == null) return;
    if (ref.read(authControllerProvider).user == null) {
      context.push('/conta/porta');
      return;
    }
    setState(() => _erro = null);
    final ok = await ref
        .read(agendaControllerProvider.notifier)
        .reservar(
          profissionalId: option.profissional.id,
          horario: option.horario,
        );
    if (!mounted) return;
    final agenda = ref.read(agendaControllerProvider);
    if (ok) {
      context.go('/consultas');
    } else if (agenda.pedindoCodigo) {
      setState(() => _codigo = true);
    } else {
      setState(
        () => _erro =
            agenda.errorMessage ??
            'Este horário acabou de ser ocupado. Busque outra opção.',
      );
    }
  }

  Future<void> _confirmarEmail() async {
    final ok = await ref
        .read(agendaControllerProvider.notifier)
        .confirmarCodigo(_codigoController.text);
    if (!mounted) return;
    if (ok)
      context.go('/consultas');
    else
      setState(
        () => _erro =
            ref.read(agendaControllerProvider).errorMessage ??
            'Confira o código e tente novamente.',
      );
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(agendaControllerProvider);
    final auth = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id) {
        setState(() {
          _sugestao = null;
          _codigo = false;
          _codigoController.clear();
        });
      }
    });
    final pro = _sugestao?.profissional;
    final slot = _sugestao?.horario;
    return Scaffold(
      appBar: AppBar(title: const Text('Consulta online')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Escolha uma especialidade. Vamos encontrar o próximo horário disponível; você confirma antes de reservar.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          if (!auth.hydrating && auth.user == null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Entre para continuar'),
                    const SizedBox(height: 6),
                    const Text(
                      'Entre na sua conta para ver médicos e horários disponíveis.',
                    ),
                    const SizedBox(height: 10),
                    FilledButton(
                      onPressed: () => context.push('/conta/porta'),
                      child: const Text('Entrar ou criar conta'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (_carregandoEspecialidades)
            const Center(child: CircularProgressIndicator())
          else if (_especialidades.isEmpty)
            Text(_erro ?? 'Nenhuma especialidade disponível.')
          else
            TutorialAnchor(
              id: 'online-specialty',
              child: DropdownButtonFormField<String>(
                value: _selecionada,
                decoration: const InputDecoration(
                  labelText: 'Especialidade',
                  border: OutlineInputBorder(),
                ),
                items: _especialidades
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: _buscando
                    ? null
                    : (value) => setState(() {
                        _selecionada = value;
                        _sugestao = null;
                        _erro = null;
                      }),
              ),
            ),
          const SizedBox(height: 12),
          if (auth.user != null)
            TutorialAnchor(
              id: 'online-search',
              child: FilledButton.icon(
                onPressed: _buscando || _selecionada == null ? null : _buscar,
                icon: _buscando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.search),
                label: Text(
                  _buscando ? 'Procurando médico…' : 'Encontrar médico',
                ),
              ),
            ),
          if (_erro != null) ...[
            const SizedBox(height: 12),
            Text(_erro!, style: const TextStyle(color: CheckmeColors.alerta)),
          ],
          if (auth.user != null && pro != null && slot != null) ...[
            const SizedBox(height: 20),
            TutorialAnchor(
              id: 'online-suggestion',
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Melhor opção disponível',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: CheckmeColors.navy,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        pro.nome,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(_selecionada ?? pro.especialidade),
                      const SizedBox(height: 8),
                      Text(
                        formatarQuando(slot.startsAt),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'A consulta acontece por videochamada. O link aparece em Consultas após confirmar.',
                      ),
                      const SizedBox(height: 14),
                      TutorialAnchor(
                        id: 'online-confirm',
                        child: FilledButton(
                          onPressed: agenda.reservando ? null : _confirmar,
                          child: Text(
                            agenda.reservando
                                ? 'Confirmando…'
                                : 'Confirmar este horário',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (auth.user != null && _codigo) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _codigoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Código enviado por e-mail',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: agenda.reservando ? null : _confirmarEmail,
              child: const Text('Confirmar e-mail e reservar'),
            ),
            TextButton(
              onPressed: agenda.reservando
                  ? null
                  : () => ref
                        .read(agendaControllerProvider.notifier)
                        .reenviarCodigo(),
              child: const Text('Reenviar código'),
            ),
          ],
          if (auth.user != null &&
              _sugestao == null &&
              !_buscando &&
              _selecionada != null) ...[
            const SizedBox(height: 14),
            const Text(
              'A busca considera profissionais aprovados e horários livres. A reserva só acontece quando você confirma.',
            ),
          ],
        ],
      ),
    );
  }
}
