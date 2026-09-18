import 'dart:io';

import 'package:checkme/domain/apperr/api_exception.dart';
import 'package:checkme/domain/care/models.dart';
import 'package:checkme/infrastructure/api/api_client.dart';
import 'package:checkme/infrastructure/api/api_config.dart';
import 'package:checkme/infrastructure/api/checkme_api.dart';

void fail(String msg) {
  stderr.writeln('FAIL $msg');
  exit(1);
}

void ok(String msg) => stdout.writeln('ok  $msg');

Future<void> main() async {
  final api = CheckmeApi(
    ApiClient(config: const ApiConfig(root: 'http://localhost:8000')),
  );
  if (!await api.ready()) {
    fail('GET /health/ready');
  }
  ok('health/ready');

  final email =
      'flutter-smoke-${DateTime.now().millisecondsSinceEpoch}@checkme.local';
  const password = 'checkme-smoke-2026';

  try {
    await api.register(
      nome: 'Smoke',
      email: email,
      password: password,
      lgpdConsent: false,
    );
    fail('expected identity.consent_required');
  } on ApiException catch (e) {
    if (e.code != 'identity.consent_required') {
      fail('consent code=${e.code}');
    }
    ok('register without LGPD');
  }

  final created = await api.register(
    nome: 'Smoke Flutter',
    email: email,
    password: password,
    lgpdConsent: true,
  );
  if (created.accessToken.isEmpty) fail('register tokens');
  ok('register with LGPD');

  final logged = await api.login(email: email, password: password);
  final bound = ApiClient(config: const ApiConfig(root: 'http://localhost:8000'));
  bound.bindAuth(
    accessToken: () => logged.accessToken,
    refreshToken: () => logged.refreshToken,
  );
  final authed = CheckmeApi(bound);

  final grave = await authed.chat(mensagem: 'dor no peito e falta de ar');
  if (grave.status != TriageStatus.grave) {
    fail('grave status=${grave.status} msg=${grave.mensagem}');
  }
  if (!grave.mensagem.toLowerCase().contains('emergência') &&
      !grave.mensagem.toLowerCase().contains('samu')) {
    fail('grave copy: ${grave.mensagem}');
  }
  ok('chat ALERTA_GRAVE');

  final leve = await authed.chat(mensagem: 'qa triagem leve');
  if (leve.status != TriageStatus.leve) {
    fail('leve status=${leve.status}');
  }
  if (leve.mensagem.isEmpty) fail('leve mensagem empty');
  ok('chat LEVE (${leve.sessaoId})');

  final restored = await authed.triagem(leve.sessaoId);
  if (restored.status != TriageStatus.leve) fail('restore status');
  if (restored.history.isEmpty) fail('restore history');
  ok('restore GET /me/triagens/{id}');

  final listed = await authed.listTriagens();
  if (listed.isEmpty) fail('list triagens empty');
  ok('list GET /me/triagens');

  final contact = await authed.contato();
  if (contact.whatsapp == null || !contact.whatsapp!.contains('wa.me')) {
    fail('contato whatsapp');
  }
  ok('contato WhatsApp');

  stdout.writeln('SMOKE PASS');
}
