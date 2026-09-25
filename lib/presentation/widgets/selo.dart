import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum SeloTom { sucesso, care, neutro }

class Selo extends StatelessWidget {
  const Selo({super.key, required this.texto, required this.tom});

  final String texto;
  final SeloTom tom;

  @override
  Widget build(BuildContext context) {
    final (cor, fundo) = switch (tom) {
      SeloTom.sucesso => (CheckmeColors.sucesso, const Color(0xFFE8F6EE)),
      SeloTom.care => (CheckmeColors.care, CheckmeColors.azulNeve),
      SeloTom.neutro => (CheckmeColors.textoSecundario, CheckmeColors.fundo),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        texto,
        style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

(String, SeloTom) seloDaConsulta({
  required String status,
  required String videoStatus,
}) {
  if (videoStatus == 'em_curso') return ('Em curso', SeloTom.care);
  return switch (status) {
    'reservada' => ('Reservada', SeloTom.sucesso),
    'confirmada' => ('Confirmada', SeloTom.sucesso),
    'reagendada' => ('Reagendada', SeloTom.sucesso),
    'cancelada' => ('Cancelada', SeloTom.neutro),
    'encerrada' => ('Encerrada', SeloTom.neutro),
    _ => (status.isEmpty ? 'Consulta' : status, SeloTom.neutro),
  };
}
