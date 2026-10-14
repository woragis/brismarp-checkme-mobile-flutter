import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import '../../widgets/cartao.dart';
import '../../widgets/cascata.dart';
import '../../widgets/logo.dart';
import '../../widgets/press_linha.dart';

class ContaMenuScreen extends ConsumerWidget {
  const ContaMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logado = ref.watch(authControllerProvider).user != null;
    final linhas = <_Item>[
      const _Item(
        grupo: 'Sua conta',
        titulo: 'Ficha',
        apoio: 'Nome, CPF e telefone',
        icone: Icons.badge_outlined,
        path: '/conta/ficha',
        privada: true,
      ),
      const _Item(
        grupo: 'Sua conta',
        titulo: 'Família',
        apoio: 'Dependentes',
        icone: Icons.group_outlined,
        path: '/conta/familia',
        privada: true,
      ),
      const _Item(
        grupo: 'Sua conta',
        titulo: 'Meus dados',
        apoio: 'Baixar o que guardamos',
        icone: Icons.download_outlined,
        path: '/conta/dados',
        privada: true,
      ),
      const _Item(
        grupo: 'Sua conta',
        titulo: 'Excluir conta',
        apoio: 'Anonimiza seus dados',
        icone: Icons.delete_outline,
        path: '/conta/excluir',
        privada: true,
      ),
    ];
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          const Logo(size: 28),
          const SizedBox(height: 24),
          Text('Conta', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          for (var i = 0; i < linhas.length; i++) ...[
            if (i == 0 || linhas[i].grupo != linhas[i - 1].grupo) ...[
              if (i != 0) const SizedBox(height: 8),
              Text(
                linhas[i].grupo,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
            ],
            Cascata(
              index: i,
              child: PressLinha(
                onTap: () {
                  final item = linhas[i];
                  if (item.privada && !logado) {
                    context.push('/conta/porta');
                    return;
                  }
                  context.push(item.path);
                },
                child: Cartao(
                  animate: false,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: CheckmeColors.azulNeve,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(linhas[i].icone, color: CheckmeColors.navy),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              linhas[i].titulo,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              linhas[i].apoio,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: CheckmeColors.care,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          Cascata(
            index: linhas.length,
            child: PressLinha(
              onTap: () {
                if (!logado) {
                  context.push('/conta/porta');
                  return;
                }
                ref.read(authControllerProvider.notifier).sair();
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Text(
                    'Sair',
                    style: TextStyle(
                      color: CheckmeColors.alerta,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.grupo,
    required this.titulo,
    required this.apoio,
    required this.icone,
    required this.path,
    this.privada = false,
  });

  final String grupo;
  final String titulo;
  final String apoio;
  final IconData icone;
  final String path;
  final bool privada;
}
