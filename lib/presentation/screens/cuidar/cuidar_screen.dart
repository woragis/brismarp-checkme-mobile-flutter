import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../domain/care/phase.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import 'conta_sheet.dart';
import 'cuidar_hub.dart';
import 'grave_screen.dart';
import 'orientacao_chat.dart';
import 'proximo_passo_screen.dart';

class CuidarScreen extends ConsumerWidget {
  const CuidarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final care = ref.watch(careControllerProvider);
    final child = switch (care.phase) {
      CareVisitante() || CareEmPaz() => const CuidarHub(),
      CareDescrevendo() || CarePedindoConta() => const OrientacaoChat(),
      CareProximoPasso(:final mensagem) =>
        ProximoPassoScreen(mensagem: mensagem),
      CareGrave(:final whatsapp) => GraveScreen(whatsapp: whatsapp),
    };

    return Scaffold(
      backgroundColor: care.phase is CareGrave
          ? CheckmeColors.alerta
          : CheckmeColors.fundo,
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: CheckmeMotion.hubToChat,
            switchInCurve: CheckmeMotion.easeOutCubic,
            switchOutCurve: CheckmeMotion.easeIn,
            child: KeyedSubtree(
              key: ValueKey(care.phase.runtimeType),
              child: child,
            ),
          ),
          if (care.hydrating)
            const ModalBarrier(dismissible: false, color: Color(0x22FFFFFF)),
          if (care.sheetOpen || care.phase is CarePedindoConta)
            const ContaSheet()
                .animate()
                .fadeIn(duration: CheckmeMotion.sheet),
        ],
      ),
    );
  }
}
