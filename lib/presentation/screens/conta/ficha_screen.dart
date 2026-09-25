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

class FichaScreen extends ConsumerStatefulWidget {
  const FichaScreen({super.key});

  @override
  ConsumerState<FichaScreen> createState() => _FichaScreenState();
}

class _FichaScreenState extends ConsumerState<FichaScreen> {
  final _nome = TextEditingController();
  final _cpf = TextEditingController();
  final _phone = TextEditingController();
  var _pronto = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_carregar);
  }

  Future<void> _carregar() async {
    if (ref.read(authControllerProvider).user == null) return;
    await ref.read(contaControllerProvider.notifier).carregar();
    if (!mounted || _pronto) return;
    final conta = ref.read(contaControllerProvider);
    final user = ref.read(authControllerProvider).user;
    _nome.text = user?.nome ?? '';
    _cpf.text = conta.cpf;
    _phone.text = conta.phone;
    _pronto = true;
    setState(() {});
  }

  @override
  void dispose() {
    _nome.dispose();
    _cpf.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authControllerProvider).user == null) {
      return const PortaScreen();
    }
    final conta = ref.watch(contaControllerProvider);
    final email = ref.watch(authControllerProvider).user?.email ?? '';
    return TelaInterna(
      titulo: 'Ficha',
      child: conta.loading && !_pronto
          ? const Center(
              child: CircularProgressIndicator(color: CheckmeColors.navy),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    children: [
                      Cartao(
                        animate: false,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Campo(controller: _nome, hint: 'Nome'),
                            const SizedBox(height: 10),
                            Campo(controller: _cpf, hint: 'CPF'),
                            const SizedBox(height: 10),
                            Campo(
                              controller: _phone,
                              hint: 'Telefone',
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              email,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
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
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Botao(
                    titulo: conta.salvando ? 'Aguarde…' : 'Salvar ficha',
                    onPressed: conta.salvando
                        ? null
                        : () => ref
                              .read(contaControllerProvider.notifier)
                              .salvar(
                                nome: _nome.text,
                                cpf: _cpf.text,
                                phone: _phone.text,
                              ),
                  ),
                ),
              ],
            ),
    );
  }
}
