class CareMessage {
  const CareMessage({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.at,
  });

  final String id;
  final String text;
  final bool fromUser;
  final DateTime at;
}

enum TriageStatus {
  continuar,
  especialidade,
  leve,
  moderado,
  grave,
  desconhecido;

  static TriageStatus parse(String? raw) {
    switch (raw) {
      case 'CONTINUAR_TRIAGEM':
      case 'CONTINUAR_ORIENTACAO':
        return TriageStatus.continuar;
      case 'ESPECIALIDADE_SUGERIDA':
        return TriageStatus.especialidade;
      case 'LEVE':
        return TriageStatus.leve;
      case 'MODERADO':
        return TriageStatus.moderado;
      case 'ALERTA_GRAVE':
        return TriageStatus.grave;
      default:
        return TriageStatus.desconhecido;
    }
  }

  bool get terminal =>
      this == especialidade ||
      this == leve ||
      this == moderado ||
      this == grave;

  String get wire {
    switch (this) {
      case TriageStatus.continuar:
        return 'CONTINUAR_ORIENTACAO';
      case TriageStatus.especialidade:
        return 'ESPECIALIDADE_SUGERIDA';
      case TriageStatus.leve:
        return 'LEVE';
      case TriageStatus.moderado:
        return 'MODERADO';
      case TriageStatus.grave:
        return 'ALERTA_GRAVE';
      case TriageStatus.desconhecido:
        return '';
    }
  }
}

class ChatReply {
  const ChatReply({
    required this.status,
    required this.mensagem,
    required this.sessaoId,
  });

  final TriageStatus status;
  final String mensagem;
  final String sessaoId;
}

class SessionView {
  const SessionView({
    required this.id,
    required this.status,
    this.history = const [],
    this.updatedAt,
  });

  final String id;
  final TriageStatus status;
  final List<CareMessage> history;
  final DateTime? updatedAt;
}

class ContactInfo {
  const ContactInfo({this.whatsapp});

  final String? whatsapp;
}
