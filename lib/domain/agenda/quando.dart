import 'models.dart';

const _meses = [
  'jan',
  'fev',
  'mar',
  'abr',
  'mai',
  'jun',
  'jul',
  'ago',
  'set',
  'out',
  'nov',
  'dez',
];

DateTime? proximoFuturo(Iterable<DateTime> inicios, DateTime agora) {
  DateTime? melhor;
  for (final inicio in inicios) {
    if (!inicio.isAfter(agora)) continue;
    if (melhor == null || inicio.isBefore(melhor)) melhor = inicio;
  }
  return melhor;
}

String formatarQuando(DateTime instante, {DateTime? agora}) {
  final local = instante.toLocal();
  final ref = (agora ?? DateTime.now()).toLocal();
  final dia = DateTime(local.year, local.month, local.day);
  final hoje = DateTime(ref.year, ref.month, ref.day);
  final hora =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (dia == hoje) return 'Hoje, $hora';
  if (dia == hoje.add(const Duration(days: 1))) return 'Amanhã, $hora';
  return '${local.day} ${_meses[local.month - 1]}, $hora';
}

List<Horario> horariosAbertos(Iterable<Horario> slots, DateTime agora) {
  final abertos = slots.where((s) => s.startsAt.isAfter(agora)).toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return abertos;
}
