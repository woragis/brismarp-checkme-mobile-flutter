import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../application/care/care_controller.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/botao.dart';

class GraveScreen extends ConsumerWidget {
  const GraveScreen({super.key, this.whatsapp});

  final String? whatsapp;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wa = (whatsapp == null || whatsapp!.isEmpty)
        ? fallbackWhatsapp
        : whatsapp!;
    return AnimatedContainer(
      duration: CheckmeMotion.grave,
      curve: CheckmeMotion.easeIn,
      color: CheckmeColors.alerta,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40)
                  .animate()
                  .fadeIn(duration: CheckmeMotion.appear),
              const SizedBox(height: 24),
              Text(
                'Procure um serviço de emergência agora',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                    ),
              ),
              const SizedBox(height: 16),
              Text(
                'Este relato tem um sinal de alarme. Não agende consulta por aqui. Ligue 192 (SAMU) ou fale com a equipe CheckMe no WhatsApp.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
              const Spacer(),
              PulseCta(
                child: Botao(
                  titulo: 'Ligar 192',
                  variante: BotaoVariante.inverso,
                  onPressed: () => _open('tel:192'),
                ),
              ),
              const SizedBox(height: 12),
              Botao(
                titulo: 'WhatsApp da equipe',
                variante: BotaoVariante.inverso,
                onPressed: () => _open(wa),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () =>
                      ref.read(careControllerProvider.notifier).voltarAoHub(),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PulseCta extends StatelessWidget {
  const PulseCta({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fade(
          begin: 0.7,
          end: 1,
          duration: CheckmeMotion.pulse,
        );
  }
}
