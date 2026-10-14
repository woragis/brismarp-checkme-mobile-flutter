import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/care/care_controller.dart';
import '../../../domain/care/models.dart';
import '../../../domain/care/phase.dart';
import '../../theme/colors.dart';
import '../../theme/motion.dart';
import 'conta_sheet.dart';
import 'cuidar_hub.dart';
import 'grave_screen.dart';
import 'horarios_screen.dart';
import 'orientacao_chat.dart';
import 'profissionais_screen.dart';
import 'proximo_passo_screen.dart';

class CuidarScreen extends ConsumerWidget {
  const CuidarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final care = ref.watch(careControllerProvider);
    final noInicio = care.phase is CareVisitante || care.phase is CareEmPaz;
    final child = switch (care.phase) {
      CareVisitante() || CareEmPaz() => const CuidarHub(),
      CareDescrevendo() || CarePedindoConta() => const OrientacaoChat(),
      CareProximoPasso(:final mensagem, :final status) => ProximoPassoScreen(
        mensagem: mensagem,
        status: status,
        relato: _relato(care.messages),
      ),
      CareEscolhendoProfissional() => const ProfissionaisScreen(),
      final CareEscolhendoHorario fase => HorariosScreen(fase: fase),
      CareGrave(:final whatsapp) => GraveScreen(whatsapp: whatsapp),
    };

    return PopScope(
      canPop: noInicio && !care.sheetOpen,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _voltar(ref);
      },
      child: Scaffold(
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
              const ContaSheet().animate().fadeIn(
                duration: CheckmeMotion.sheet,
              ),
          ],
        ),
      ),
    );
  }
}

void _voltar(WidgetRef ref) {
  final care = ref.read(careControllerProvider);
  final notifier = ref.read(careControllerProvider.notifier);
  if (care.sheetOpen || care.phase is CarePedindoConta) {
    notifier.fecharSheet();
    return;
  }
  switch (care.phase) {
    case CareEscolhendoHorario():
      notifier.voltarAosProfissionais();
    case CareEscolhendoProfissional():
      notifier.voltarAoPasso();
    case CareProximoPasso() || CareDescrevendo() || CareGrave():
      notifier.voltarAoHub();
    case CareVisitante() || CareEmPaz() || CarePedindoConta():
      break;
  }
}

String _relato(List<CareMessage> messages) {
  for (var i = messages.length - 1; i >= 0; i--) {
    if (messages[i].fromUser && messages[i].text.trim().isNotEmpty) {
      return messages[i].text.trim();
    }
  }
  return '';
}
