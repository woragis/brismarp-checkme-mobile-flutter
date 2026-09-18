import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../application/identity/auth_controller.dart';
import '../../../domain/apperr/api_exception.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/botao.dart';
import '../../widgets/campo.dart';
import '../../widgets/logo.dart';

class ContaSheet extends ConsumerStatefulWidget {
  const ContaSheet({super.key});

  @override
  ConsumerState<ContaSheet> createState() => _ContaSheetState();
}

class _ContaSheetState extends ConsumerState<ContaSheet> {
  final _nome = TextEditingController();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  final _indicacao = TextEditingController();
  bool _cadastro = true;
  bool _lgpd = false;
  bool _enviando = false;
  String? _erro;

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _senha.dispose();
    _indicacao.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    setState(() {
      _erro = null;
      _enviando = true;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_cadastro) {
        if (!_lgpd) {
          setState(() {
            _erro = 'Aceite o uso dos seus dados (LGPD) para criar a conta.';
            _enviando = false;
          });
          return;
        }
        if (_senha.text.length < 8) {
          setState(() {
            _erro = 'A senha precisa ter pelo menos 8 caracteres.';
            _enviando = false;
          });
          return;
        }
        await auth.criar(
          nome: _nome.text.trim(),
          email: _email.text.trim(),
          password: _senha.text,
          lgpdConsent: _lgpd,
          affiliateCode: _indicacao.text.trim(),
        );
      } else {
        await auth.entrar(
          email: _email.text.trim(),
          password: _senha.text,
        );
      }
      await ref.read(careControllerProvider.notifier).depoisDoLogin();
    } on ApiException catch (e) {
      setState(() => _erro = e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CheckmeColors.overlay,
      child: GestureDetector(
        onTap: () => ref.read(careControllerProvider.notifier).fecharSheet(),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.88,
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                20,
                24,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              decoration: const BoxDecoration(
                color: CheckmeColors.cartao,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: CheckmeColors.borda,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Logo(size: 28),
                    const SizedBox(height: 16),
                    Text(
                      'Continue a orientação',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Crie a conta gratuita para receber a orientação completa. Em caso grave, a emergência não espera login.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    if (_cadastro) ...[
                      Campo(
                        controller: _nome,
                        hint: 'Nome',
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                      ),
                      const SizedBox(height: 10),
                    ],
                    Campo(
                      controller: _email,
                      hint: 'E-mail',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                    ),
                    const SizedBox(height: 10),
                    Campo(
                      controller: _senha,
                      hint: 'Senha',
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => _confirmar(),
                    ),
                    if (_cadastro) ...[
                      const SizedBox(height: 10),
                      Campo(
                        controller: _indicacao,
                        hint: 'Código de indicação (opcional)',
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => setState(() => _lgpd = !_lgpd),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _lgpd,
                              activeColor: CheckmeColors.navy,
                              onChanged: (v) =>
                                  setState(() => _lgpd = v ?? false),
                            ),
                            const Expanded(
                              child: Text(
                                'Autorizo o tratamento dos meus dados (LGPD) para criar a conta.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CheckmeColors.texto,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (_erro != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _erro!,
                        style: const TextStyle(
                          color: CheckmeColors.alerta,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Botao(
                      titulo: _enviando
                          ? 'Aguarde…'
                          : (_cadastro ? 'Criar conta grátis' : 'Entrar'),
                      onPressed: _enviando ? null : _confirmar,
                    ),
                    Botao(
                      titulo: _cadastro
                          ? 'Já tenho conta — entrar'
                          : 'Ainda não tenho conta — criar grátis',
                      variante: BotaoVariante.terciario,
                      onPressed: () => setState(() {
                        _cadastro = !_cadastro;
                        _erro = null;
                      }),
                    ),
                    Botao(
                      titulo: 'Preciso de emergência agora',
                      variante: BotaoVariante.perigo,
                      onPressed: () => ref
                          .read(careControllerProvider.notifier)
                          .abrirUrgenciaSemConta(),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: CheckmeMotion.sheet,
                  curve: CheckmeMotion.easeOutCubic,
                )
                .fadeIn(duration: CheckmeMotion.sheet),
          ),
        ),
      ),
    );
  }
}
