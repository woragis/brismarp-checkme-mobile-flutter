import 'models.dart';

sealed class CarePhase {
  const CarePhase();
}

class CareVisitante extends CarePhase {
  const CareVisitante();
}

class CareEmPaz extends CarePhase {
  const CareEmPaz({required this.primeiroNome});

  final String primeiroNome;
}

class CareDescrevendo extends CarePhase {
  const CareDescrevendo();
}

class CarePedindoConta extends CarePhase {
  const CarePedindoConta();
}

class CareProximoPasso extends CarePhase {
  const CareProximoPasso({required this.mensagem, required this.status});

  final String mensagem;
  final TriageStatus status;
}

class CareEscolhendoProfissional extends CarePhase {
  const CareEscolhendoProfissional({
    required this.mensagem,
    required this.status,
  });

  final String mensagem;
  final TriageStatus status;
}

class CareEscolhendoHorario extends CarePhase {
  const CareEscolhendoHorario({
    required this.mensagem,
    required this.status,
    required this.profissionalId,
    required this.nome,
    required this.especialidade,
  });

  final String mensagem;
  final TriageStatus status;
  final String profissionalId;
  final String nome;
  final String especialidade;
}

class CareGrave extends CarePhase {
  const CareGrave({this.whatsapp});

  final String? whatsapp;
}

class CareSnapshot {
  const CareSnapshot({
    required this.phase,
    this.messages = const [],
    this.sessaoId,
    this.waiting = false,
    this.errorMessage,
    this.errorCode,
    this.sheetOpen = false,
    this.hydrating = false,
    this.rascunho = '',
    this.pausa,
  });

  final CarePhase phase;
  final List<CareMessage> messages;
  final String? sessaoId;
  final bool waiting;
  final String? errorMessage;
  final String? errorCode;
  final bool sheetOpen;
  final bool hydrating;
  final String rascunho;
  final CarePhase? pausa;

  bool get orientacaoAberta => pausa != null;

  CareSnapshot copyWith({
    CarePhase? phase,
    List<CareMessage>? messages,
    String? sessaoId,
    bool clearSessao = false,
    bool? waiting,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    bool? sheetOpen,
    bool? hydrating,
    String? rascunho,
    CarePhase? pausa,
    bool clearPausa = false,
  }) {
    return CareSnapshot(
      phase: phase ?? this.phase,
      messages: messages ?? this.messages,
      sessaoId: clearSessao ? null : (sessaoId ?? this.sessaoId),
      waiting: waiting ?? this.waiting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      sheetOpen: sheetOpen ?? this.sheetOpen,
      hydrating: hydrating ?? this.hydrating,
      rascunho: rascunho ?? this.rascunho,
      pausa: clearPausa ? null : (pausa ?? this.pausa),
    );
  }
}
