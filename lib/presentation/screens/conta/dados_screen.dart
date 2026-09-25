import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/conta/conta_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../theme/colors.dart';
import 'porta_screen.dart';
import 'tela_interna.dart';

class DadosScreen extends ConsumerStatefulWidget {
  const DadosScreen({super.key});

  @override
  ConsumerState<DadosScreen> createState() => _DadosScreenState();
}

class _DadosScreenState extends ConsumerState<DadosScreen> {
  String? _json;
  var _carregando = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_baixar);
  }

  Future<void> _baixar() async {
    if (ref.read(authControllerProvider).user == null) return;
    final json = await ref.read(contaControllerProvider.notifier).exportar();
    if (!mounted) return;
    setState(() {
      _json = json;
      _carregando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authControllerProvider).user == null) {
      return const PortaScreen();
    }
    final erro = ref.watch(contaControllerProvider).errorMessage;
    return TelaInterna(
      titulo: 'Meus dados',
      child: _carregando
          ? const Center(
              child: CircularProgressIndicator(color: CheckmeColors.navy),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              children: [
                SelectableText(
                  _json ?? erro ?? 'Não foi possível baixar seus dados.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
    );
  }
}
