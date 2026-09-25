class Profissional {
  const Profissional({
    required this.id,
    required this.nome,
    required this.especialidade,
    this.proximo,
  });

  final String id;
  final String nome;
  final String especialidade;
  final DateTime? proximo;

  Profissional copyWith({DateTime? proximo}) {
    return Profissional(
      id: id,
      nome: nome,
      especialidade: especialidade,
      proximo: proximo ?? this.proximo,
    );
  }
}

class Horario {
  const Horario({
    required this.id,
    required this.startsAt,
    required this.endsAt,
  });

  final String id;
  final DateTime startsAt;
  final DateTime endsAt;
}

class Consulta {
  const Consulta({
    required this.id,
    required this.profissionalId,
    required this.startsAt,
    required this.status,
    this.videoStatus = '',
  });

  final String id;
  final String profissionalId;
  final DateTime startsAt;
  final String status;
  final String videoStatus;

  bool get podeEntrar => status != 'cancelada' && videoStatus != 'encerrada';
}
