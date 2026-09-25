import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/identity/auth_controller.dart';
import '../../../application/planos/planos_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/campo.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/ir_para_cuidar.dart';
import '../../widgets/logo.dart';
import '../../widgets/selo.dart';

class PlanosScreen extends ConsumerStatefulWidget {
  const PlanosScreen({super.key});

  @override
  ConsumerState<PlanosScreen> createState() => _PlanosScreenState();
}

class _PlanosScreenState extends ConsumerState<PlanosScreen> {
  final _cupom = TextEditingController();
  final _codigo = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(planosControllerProvider.notifier).carregar(),
    );
  }

  @override
  void dispose() {
    _cupom.dispose();
    _codigo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final planos = ref.watch(planosControllerProvider);
    final logado = auth.user != null;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const Logo(size: 28),
          const SizedBox(height: 24),
          Text('Planos', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          if (planos.loading && planos.planos.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(color: CheckmeColors.navy),
              ),
            )
          else if (planos.planos.isEmpty)
            Text(
              planos.errorMessage ?? 'Nenhum plano disponível agora.',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else ...[
            for (var i = 0; i < planos.planos.length; i++) ...[
              const SizedBox(height: 8),
              Cascata(
                index: i,
                child: Cartao(
                  animate: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _reais(planos.planos[i].precoParcela),
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(fontSize: 26),
                            ),
                          ),
                          if (planos.planoAtivo == planos.planos[i].nome)
                            const Selo(
                              texto: 'Seu plano',
                              tom: SeloTom.sucesso,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planos.planos[i].nome,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        planos.planos[i].descricaoParcela.isEmpty
                            ? '${planos.planos[i].parcelas}x'
                            : '${planos.planos[i].parcelas}x · ${planos.planos[i].descricaoParcela}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (logado) ...[
                        const SizedBox(height: 8),
                        Botao(
                          titulo: planos.contratando ? 'Aguarde…' : 'Contratar',
                          onPressed: planos.contratando
                              ? null
                              : () => ref
                                    .read(planosControllerProvider.notifier)
                                    .contratar(planos.planos[i].id),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            if (logado) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Campo(controller: _cupom, hint: 'Cupom'),
                  ),
                  const SizedBox(width: 8),
                  Botao(
                    titulo: 'Validar',
                    expand: false,
                    variante: BotaoVariante.secundario,
                    onPressed: planos.contratando
                        ? null
                        : () => ref
                              .read(planosControllerProvider.notifier)
                              .validar(_cupom.text),
                  ),
                ],
              ),
              if (planos.cupom != null) ...[
                const SizedBox(height: 8),
                Text(
                  _cupomTexto(planos.cupom!),
                  style: const TextStyle(
                    color: CheckmeColors.sucesso,
                    fontSize: 13,
                  ),
                ),
              ],
              if (planos.pedindoCodigo) ...[
                const SizedBox(height: 8),
                Campo(
                  controller: _codigo,
                  hint: 'Código do e-mail',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Botao(
                  titulo: 'Confirmar código',
                  onPressed: planos.contratando
                      ? null
                      : () => ref
                            .read(planosControllerProvider.notifier)
                            .confirmarCodigo(_codigo.text),
                ),
                Botao(
                  titulo: 'Reenviar código',
                  variante: BotaoVariante.terciario,
                  onPressed: planos.contratando
                      ? null
                      : () => ref
                            .read(planosControllerProvider.notifier)
                            .reenviarCodigo(),
                ),
              ],
            ] else ...[
              const SizedBox(height: 16),
              const IrParaCuidar(
                texto: 'Para contratar, volte para Cuidar e toque em Já tenho conta.',
              ),
            ],
            if (logado && planos.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                planos.errorMessage!,
                style: TextStyle(
                  color: planos.errorCode == null
                      ? CheckmeColors.textoSecundario
                      : CheckmeColors.alerta,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

String _reais(double valor) {
  final texto = valor.toStringAsFixed(2).replaceAll('.', ',');
  return 'R\$ $texto';
}

String _cupomTexto(Cupom cupom) {
  if (cupom.kind == 'percent') return 'Cupom aceito: ${cupom.value}%';
  if (cupom.kind == 'valor') return 'Cupom aceito: ${_reais(cupom.value)}';
  return 'Cupom aceito.';
}
