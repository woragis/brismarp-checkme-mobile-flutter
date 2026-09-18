import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/apperr/api_exception.dart';
import '../../domain/care/models.dart';
import '../../domain/care/phase.dart';
import '../../domain/care/visible_text.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../../infrastructure/storage/session_store.dart';
import '../identity/auth_controller.dart';

const saudacao =
    'Olá. Pode me contar o que você está sentindo? Descreva com as suas '
    'palavras — quando começou, o que piorou, se há dificuldade para '
    'respirar ou outro sinal que te preocupe.';

const fallbackWhatsapp = 'https://wa.me/5582996690508';

String sessaoKey(String userId) => 'checkme.sessao.$userId';

CareMessage _msg(String text, {required bool fromUser}) {
  return CareMessage(
    id: '${DateTime.now().microsecondsSinceEpoch}-${fromUser ? 'u' : 'a'}',
    text: text,
    fromUser: fromUser,
    at: DateTime.now(),
  );
}

class CareController extends Notifier<CareSnapshot> {
  late final CheckmeApi _api;
  late final SessionStore _store;
  String? _pending;
  String? _whatsapp;

  @override
  CareSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    _store = ref.read(sessionStoreProvider);
    ref.listen<AuthSnapshot>(authControllerProvider, (prev, next) {
      if (next.hydrating) return;
      final authJustReady = prev == null || prev.hydrating;
      final userChanged = prev?.user?.id != next.user?.id;
      if (authJustReady || userChanged) {
        Future.microtask(() => hydrate(flushPending: false));
      }
    });
    Future.microtask(hydrate);
    return const CareSnapshot(phase: CareVisitante(), hydrating: true);
  }

  Future<void> hydrate({bool flushPending = false}) async {
    final auth = ref.read(authControllerProvider);
    if (auth.hydrating) return;
    final user = auth.user;
    if (user == null) {
      if (state.phase is CareDescrevendo ||
          state.phase is CarePedindoConta ||
          state.phase is CareGrave) {
        state = state.copyWith(hydrating: false);
        return;
      }
      _pending = null;
      state = const CareSnapshot(phase: CareVisitante());
      return;
    }
    state = state.copyWith(hydrating: true, sheetOpen: false);
    try {
      await _loadContact();
      final saved = await _store.read(sessaoKey(user.id));
      SessionView? view;
      if (saved != null && saved.isNotEmpty) {
        try {
          view = await _api.triagem(saved);
        } on ApiException {
          view = null;
        }
      }
      view ??= await _pickOpenOrLatest();
      if (view == null) {
        state = CareSnapshot(phase: CareEmPaz(primeiroNome: user.primeiroNome));
        return;
      }
      await _applyView(view, user.primeiroNome);
      if (flushPending && _pending != null) {
        final text = _pending!;
        _pending = null;
        await enviar(text, alreadyBubbled: false);
      }
    } on ApiException catch (e) {
      state = CareSnapshot(
        phase: CareEmPaz(primeiroNome: user.primeiroNome),
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> comecarOrientacao() async {
    final greeting = _msg(saudacao, fromUser: false);
    state = CareSnapshot(
      phase: const CareDescrevendo(),
      messages: [greeting],
    );
  }

  void abrirSheet() {
    state = state.copyWith(sheetOpen: true, clearError: true);
  }

  void fecharSheet() {
    _pending = null;
    final phase = state.phase is CarePedindoConta
        ? const CareDescrevendo()
        : state.phase;
    state = state.copyWith(sheetOpen: false, phase: phase, clearError: true);
  }

  Future<void> enviar(String texto, {bool alreadyBubbled = false}) async {
    final trimmed = texto.trim();
    if (trimmed.isEmpty || state.waiting) return;

    final messages = [
      ...state.messages,
      if (!alreadyBubbled) _msg(trimmed, fromUser: true),
    ];
    final auth = ref.read(authControllerProvider);

    if (!auth.autenticado) {
      _pending = trimmed;
      state = state.copyWith(
        phase: const CarePedindoConta(),
        messages: messages,
        sheetOpen: true,
        waiting: false,
        clearError: true,
      );
      return;
    }

    state = state.copyWith(
      phase: const CareDescrevendo(),
      messages: messages,
      waiting: true,
      sheetOpen: false,
      clearError: true,
    );

    try {
      final reply = await _api.chat(
        mensagem: trimmed,
        sessaoId: state.sessaoId,
      );
      await _store.write(sessaoKey(auth.user!.id), reply.sessaoId);
      final visible = reply.mensagem.isEmpty
          ? 'A orientação inicial fechou. O próximo passo é falar com um profissional da rede.'
          : reply.mensagem;
      final nextMessages = [
        ...messages,
        if (visible.isNotEmpty && reply.status != TriageStatus.grave)
          _msg(visible, fromUser: false),
      ];

      if (reply.status == TriageStatus.grave) {
        await _loadContact();
        state = CareSnapshot(
          phase: CareGrave(whatsapp: _whatsapp ?? fallbackWhatsapp),
          messages: nextMessages,
          sessaoId: reply.sessaoId,
        );
        return;
      }
      if (reply.status == TriageStatus.leve ||
          reply.status == TriageStatus.moderado) {
        state = CareSnapshot(
          phase: CareProximoPasso(mensagem: visible, status: reply.status),
          messages: nextMessages,
          sessaoId: reply.sessaoId,
        );
        return;
      }
      state = CareSnapshot(
        phase: const CareDescrevendo(),
        messages: nextMessages,
        sessaoId: reply.sessaoId,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        waiting: false,
        errorCode: e.code,
        errorMessage: e.message,
        messages: messages,
      );
    }
  }

  Future<void> depoisDoLogin() async {
    final pending = _pending;
    _pending = null;
    state = state.copyWith(sheetOpen: false);
    await hydrate(flushPending: false);
    if (pending != null && pending.isNotEmpty) {
      await enviar(pending, alreadyBubbled: true);
    }
  }

  Future<void> novaOrientacao() async {
    final auth = ref.read(authControllerProvider);
    final userId = auth.user?.id;
    if (userId != null) {
      await _store.delete(sessaoKey(userId));
    }
    await comecarOrientacao();
  }

  void voltarAoHub() {
    final auth = ref.read(authControllerProvider);
    if (auth.user == null) {
      state = const CareSnapshot(phase: CareVisitante());
      return;
    }
    state = CareSnapshot(
      phase: CareEmPaz(primeiroNome: auth.user!.primeiroNome),
      sessaoId: state.sessaoId,
    );
  }

  void abrirUrgenciaSemConta() {
    _pending = null;
    state = CareSnapshot(
      phase: CareGrave(whatsapp: _whatsapp ?? fallbackWhatsapp),
      messages: state.messages,
      sheetOpen: false,
    );
  }

  Future<void> _applyView(SessionView view, String primeiroNome) async {
    if (view.status == TriageStatus.grave) {
      await _loadContact();
      state = CareSnapshot(
        phase: CareGrave(whatsapp: _whatsapp ?? fallbackWhatsapp),
        messages: view.history,
        sessaoId: view.id,
      );
      return;
    }
    if (view.status == TriageStatus.leve ||
        view.status == TriageStatus.moderado) {
      CareMessage? lastIa;
      for (final m in view.history) {
        if (!m.fromUser) lastIa = m;
      }
      final mensagem = (lastIa != null && lastIa.text.isNotEmpty)
          ? lastIa.text
          : visibleOrientationText(view.soap);
      state = CareSnapshot(
        phase: CareProximoPasso(
          mensagem: mensagem.isNotEmpty
              ? mensagem
              : 'A orientação inicial fechou. O próximo passo é falar com um profissional da rede.',
          status: view.status,
        ),
        messages: view.history,
        sessaoId: view.id,
      );
      return;
    }
    final msgs = view.history.isEmpty
        ? [_msg(saudacao, fromUser: false)]
        : view.history;
    state = CareSnapshot(
      phase: const CareDescrevendo(),
      messages: msgs,
      sessaoId: view.id,
    );
  }

  Future<SessionView?> _pickOpenOrLatest() async {
    final list = await _api.listTriagens();
    if (list.isEmpty) return null;
    SessionView? open;
    for (final s in list) {
      if (s.status == TriageStatus.continuar ||
          s.status == TriageStatus.desconhecido) {
        open = s;
        break;
      }
    }
    final pick = open ?? list.first;
    return _api.triagem(pick.id);
  }

  Future<void> _loadContact() async {
    if (_whatsapp != null) return;
    try {
      final c = await _api.contato();
      _whatsapp = (c.whatsapp == null || c.whatsapp!.isEmpty)
          ? fallbackWhatsapp
          : c.whatsapp;
    } catch (_) {
      _whatsapp = fallbackWhatsapp;
    }
  }
}

final careControllerProvider =
    NotifierProvider<CareController, CareSnapshot>(CareController.new);

final apiReadyProvider = FutureProvider<bool>((ref) async {
  return ref.watch(checkmeApiProvider).ready();
});
