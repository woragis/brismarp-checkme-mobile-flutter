import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../domain/care/models.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import '../../widgets/campo.dart';

class OrientacaoChat extends ConsumerStatefulWidget {
  const OrientacaoChat({super.key});

  @override
  ConsumerState<OrientacaoChat> createState() => _OrientacaoChatState();
}

class _OrientacaoChatState extends ConsumerState<OrientacaoChat> {
  final _texto = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _texto.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _enviar() {
    final t = _texto.text;
    _texto.clear();
    ref.read(careControllerProvider.notifier).enviar(t);
  }

  @override
  Widget build(BuildContext context) {
    final care = ref.watch(careControllerProvider);
    ref.listen(careControllerProvider, (prev, next) {
      if (next.messages.length != prev?.messages.length || next.waiting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!_scroll.hasClients) return;
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: CheckmeMotion.bubble,
            curve: CheckmeMotion.easeOut,
          );
        });
      }
    });

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () =>
                      ref.read(careControllerProvider.notifier).voltarAoHub(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  color: CheckmeColors.navy,
                ),
                Expanded(
                  child: Text(
                    'Orientação inicial',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: care.messages.length + (care.waiting ? 1 : 0),
              itemBuilder: (context, i) {
                if (i >= care.messages.length) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: ThinkingDots(),
                    ),
                  );
                }
                return Bolha(message: care.messages[i]);
              },
            ),
          ),
          if (care.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                care.errorMessage!,
                style: const TextStyle(color: CheckmeColors.alerta, fontSize: 13),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Campo(
                    controller: _texto,
                    hint: 'O que você está sentindo?',
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _enviar(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: care.waiting ? null : _enviar,
                  style: IconButton.styleFrom(
                    backgroundColor: CheckmeColors.navy,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Bolha extends StatelessWidget {
  const Bolha({super.key, required this.message});

  final CareMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.fromUser;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: mine ? CheckmeColors.navy : CheckmeColors.azulNeve,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: mine ? Colors.white : CheckmeColors.texto,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      )
          .animate()
          .fadeIn(duration: CheckmeMotion.bubble)
          .slideY(begin: 0.08, end: 0, duration: CheckmeMotion.bubble),
    );
  }
}

class ThinkingDots extends StatelessWidget {
  const ThinkingDots({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: CheckmeColors.azulNeve,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: const Dot()
                .animate(onPlay: (c) => c.repeat())
                .fade(
                  begin: 0.3,
                  end: 1,
                  duration: CheckmeMotion.thinking,
                  delay: Duration(milliseconds: 150 * i),
                ),
          );
        }),
      ),
    );
  }
}

class Dot extends StatelessWidget {
  const Dot({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: CheckmeColors.navy,
        shape: BoxShape.circle,
      ),
    );
  }
}
