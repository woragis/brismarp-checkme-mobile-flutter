import 'package:checkme/domain/agenda/models.dart';
import 'package:checkme/domain/agenda/quando.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final agora = DateTime(2026, 9, 25, 12);

  test('próximo horário é o futuro mais cedo', () {
    final cedo = DateTime(2026, 9, 25, 16, 30);
    final tarde = DateTime(2026, 9, 26, 9);
    final passado = DateTime(2026, 9, 25, 8);
    expect(proximoFuturo([tarde, passado, cedo], agora), cedo);
  });

  test('formata hoje, amanhã e outro dia', () {
    expect(
      formatarQuando(DateTime(2026, 9, 25, 16, 5), agora: agora),
      'Hoje, 16:05',
    );
    expect(
      formatarQuando(DateTime(2026, 9, 26, 9), agora: agora),
      'Amanhã, 09:00',
    );
    expect(
      formatarQuando(DateTime(2026, 9, 28, 11, 15), agora: agora),
      '28 set, 11:15',
    );
  });

  test('horários abertos ignoram o passado e ordenam', () {
    final slots = horariosAbertos([
      Horario(
        id: 'b',
        startsAt: DateTime(2026, 9, 26, 9),
        endsAt: DateTime(2026, 9, 26, 9, 30),
      ),
      Horario(
        id: 'a',
        startsAt: DateTime(2026, 9, 25, 8),
        endsAt: DateTime(2026, 9, 25, 8, 30),
      ),
      Horario(
        id: 'c',
        startsAt: DateTime(2026, 9, 25, 16, 30),
        endsAt: DateTime(2026, 9, 25, 17),
      ),
    ], agora);
    expect(slots.map((s) => s.id), ['c', 'b']);
  });
}
