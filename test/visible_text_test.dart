import 'package:flutter_test/flutter_test.dart';

import 'package:checkme/domain/care/models.dart';
import 'package:checkme/domain/care/visible_text.dart';

void main() {
  group('visibleOrientationText', () {
    test('keeps plain Portuguese', () {
      expect(
        visibleOrientationText('Pode hidratar e observar.'),
        'Pode hidratar e observar.',
      );
    });

    test('hides SOAP JSON and keeps inner mensagem', () {
      const raw =
          '{"status":"LEVE","mensagem":"Próximo passo: Pediatria.","soap":{"S":"x"}}';
      expect(visibleOrientationText(raw), 'Próximo passo: Pediatria.');
    });

    test('returns empty for SOAP without patient copy', () {
      expect(visibleOrientationText('{"S":"dor","O":"-","A":"-","P":"-"}'), '');
    });
  });

  test('TriageStatus.parse maps wire values', () {
    expect(TriageStatus.parse('ALERTA_GRAVE'), TriageStatus.grave);
    expect(TriageStatus.parse('LEVE').terminal, isTrue);
    expect(TriageStatus.parse('CONTINUAR_TRIAGEM').terminal, isFalse);
  });
}
