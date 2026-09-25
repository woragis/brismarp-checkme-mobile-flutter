import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/conta/conta_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/botao.dart';
import '../../widgets/campo.dart';
import '../../widgets/cartao.dart';
import 'porta_screen.dart';
import 'tela_interna.dart';

class FamiliaScreen extends ConsumerStatefulWidget {
  const FamiliaScreen({super.key});

  @override
  ConsumerState<FamiliaScreen> createState() => _FamiliaScreenState();
}

class _FamiliaScreenState extends ConsumerState<FamiliaScreen> {
  final _nome = TextEditingController();
  final _parentesco = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (ref.read(authControllerProvider).user != null) {
        ref.read(contaControllerProvider.notifier).carregar();
      }
    });
  }

  @override
  void dispose() {
    _nome.dispose();
    _parentesco.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authControllerProvider).user == null) {
      return const PortaScreen();
    }
    final conta = ref.watch(contaControllerProvider);
    return TelaInterna(
      titulo: 'Família',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          if (conta.dependentes.isEmpty)
            Text(
              'Ninguém da família cadastrado ainda.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          for (final dep in conta.dependentes) ...[
            const SizedBox(height: 8),
            Cartao(
              animate: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dep.nome,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (dep.kinship.isNotEmpty)
                          Text(
                            dep.kinship,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: conta.salvando
                        ? null
                        : () => ref
                              .read(contaControllerProvider.notifier)
                              .remover(dep.id),
                    child: const Text(
                      'Remover',
                      style: TextStyle(color: CheckmeColors.alerta),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Cartao(
            animate: false,
            child: Column(
              children: [
                Campo(controller: _nome, hint: 'Nome do dependente'),
                const SizedBox(height: 10),
                Campo(controller: _parentesco, hint: 'Parentesco'),
                if (conta.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    conta.errorMessage!,
                    style: const TextStyle(
                      color: CheckmeColors.alerta,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Botao(
                  titulo: 'Adicionar dependente',
                  variante: BotaoVariante.secundario,
                  onPressed: conta.salvando
                      ? null
                      : () async {
                          await ref
                              .read(contaControllerProvider.notifier)
                              .adicionar(
                                nome: _nome.text,
                                kinship: _parentesco.text,
                              );
                          if (ref.read(contaControllerProvider).errorMessage ==
                              null) {
                            _nome.clear();
                            _parentesco.clear();
                          }
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
