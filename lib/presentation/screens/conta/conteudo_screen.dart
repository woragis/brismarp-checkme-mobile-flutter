import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/conteudo/conteudo_controller.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/press_linha.dart';
import 'tela_interna.dart';

enum ConteudoTipo { especialidades, rede, faq }

class ConteudoScreen extends ConsumerStatefulWidget {
  const ConteudoScreen({super.key, required this.tipo});

  final ConteudoTipo tipo;

  @override
  ConsumerState<ConteudoScreen> createState() => _ConteudoScreenState();
}

class _ConteudoScreenState extends ConsumerState<ConteudoScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final api = ref.read(conteudoControllerProvider.notifier);
      switch (widget.tipo) {
        case ConteudoTipo.especialidades:
          api.carregarEspecialidades();
        case ConteudoTipo.rede:
          api.carregarRede();
        case ConteudoTipo.faq:
          api.carregarFaq();
      }
    });
  }

  String get _titulo => switch (widget.tipo) {
    ConteudoTipo.especialidades => 'Especialidades',
    ConteudoTipo.rede => 'Rede credenciada',
    ConteudoTipo.faq => 'FAQ',
  };

  @override
  Widget build(BuildContext context) {
    final conteudo = ref.watch(conteudoControllerProvider);
    final vazio = switch (widget.tipo) {
      ConteudoTipo.especialidades => conteudo.especialidades.isEmpty,
      ConteudoTipo.rede => conteudo.rede.isEmpty,
      ConteudoTipo.faq => conteudo.faq.isEmpty,
    };
    return TelaInterna(
      titulo: _titulo,
      destinoSemPilha: '/cuidar',
      child: conteudo.loading && vazio
          ? const Center(
              child: CircularProgressIndicator(color: CheckmeColors.navy),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                if (vazio)
                  Text(
                    conteudo.errorMessage ?? 'Nada por aqui agora.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else
                  ...switch (widget.tipo) {
                    ConteudoTipo.especialidades => [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final nome in conteudo.especialidades)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: CheckmeColors.azulNeve,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                nome,
                                style: const TextStyle(
                                  color: CheckmeColors.navy,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                    ConteudoTipo.rede => [
                      for (var i = 0; i < conteudo.rede.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Cascata(
                            index: i,
                            child: Cartao(
                              animate: false,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    conteudo.rede[i].especialidade,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _Coluna(
                                        titulo: 'Particular',
                                        valor: conteudo.rede[i].particular,
                                      ),
                                      _Coluna(
                                        titulo: 'Nosso valor',
                                        valor: conteudo.rede[i].nossoValor,
                                      ),
                                      _Coluna(
                                        titulo: 'Economia',
                                        valor: conteudo.rede[i].economia,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                    ConteudoTipo.faq => [
                      for (var i = 0; i < conteudo.faq.length; i++)
                        Cascata(
                          index: i,
                          child: _FaqTile(item: conteudo.faq[i]),
                        ),
                    ],
                  },
              ],
            ),
    );
  }
}

class _Coluna extends StatelessWidget {
  const _Coluna({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            valor,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatefulWidget {
  const _FaqTile({required this.item});

  final Pergunta item;

  @override
  State<_FaqTile> createState() => _FaqTileState();
}

class _FaqTileState extends State<_FaqTile> {
  var _aberta = false;

  @override
  Widget build(BuildContext context) {
    return PressLinha(
      onTap: () => setState(() => _aberta = !_aberta),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.pergunta,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  _aberta ? Icons.expand_less : Icons.expand_more,
                  color: CheckmeColors.navy,
                ),
              ],
            ),
            AnimatedSize(
              duration: CheckmeMotion.faq,
              curve: CheckmeMotion.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _aberta
                  ? Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.item.resposta,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
