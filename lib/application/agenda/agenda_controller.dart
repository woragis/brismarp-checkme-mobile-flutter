import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/agenda/models.dart';
import '../../domain/agenda/quando.dart';
import '../../domain/apperr/api_exception.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../identity/auth_controller.dart';

class AgendaSnapshot {
  const AgendaSnapshot({
    this.profissionais = const [],
    this.horarios = const [],
    this.consultas = const [],
    this.loading = false,
    this.reservando = false,
    this.pedindoCodigo = false,
    this.salaId,
    this.reagendandoId,
    this.errorMessage,
    this.errorCode,
  });

  final List<Profissional> profissionais;
  final List<Horario> horarios;
  final List<Consulta> consultas;
  final bool loading;
  final bool reservando;
  final bool pedindoCodigo;
  final String? salaId;
  final String? reagendandoId;
  final String? errorMessage;
  final String? errorCode;

  String nomeDo(String profissionalId) {
    for (final pro in profissionais) {
      if (pro.id == profissionalId && pro.nome.isNotEmpty) return pro.nome;
    }
    return '';
  }

  AgendaSnapshot copyWith({
    List<Profissional>? profissionais,
    List<Horario>? horarios,
    List<Consulta>? consultas,
    bool? loading,
    bool? reservando,
    bool? pedindoCodigo,
    String? salaId,
    bool clearSala = false,
    String? reagendandoId,
    bool clearReagendar = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return AgendaSnapshot(
      profissionais: profissionais ?? this.profissionais,
      horarios: horarios ?? this.horarios,
      consultas: consultas ?? this.consultas,
      loading: loading ?? this.loading,
      reservando: reservando ?? this.reservando,
      pedindoCodigo: pedindoCodigo ?? this.pedindoCodigo,
      salaId: clearSala ? null : (salaId ?? this.salaId),
      reagendandoId: clearReagendar
          ? null
          : (reagendandoId ?? this.reagendandoId),
      errorMessage: errorMessage ?? (clearError ? null : this.errorMessage),
      errorCode: errorCode ?? (clearError ? null : this.errorCode),
    );
  }
}

class AgendaController extends Notifier<AgendaSnapshot> {
  late final CheckmeApi _api;
  Horario? _pendente;
  String? _pendentePro;
  String? _pendenteSessao;

  @override
  AgendaSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    return const AgendaSnapshot();
  }

  Future<void> carregarProfissionais() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final lista = await _api.profissionais();
      state = state.copyWith(profissionais: lista, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        profissionais: const [],
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> carregarHorarios(String profissionalId) async {
    state = state.copyWith(loading: true, clearError: true, horarios: const []);
    try {
      final slots = horariosAbertos(
        await _api.horarios(profissionalId),
        DateTime.now(),
      );
      state = state.copyWith(horarios: slots, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> carregarConsultas() async {
    if (ref.read(authControllerProvider).user == null) {
      state = state.copyWith(consultas: const [], loading: false);
      return;
    }
    state = state.copyWith(loading: true, clearError: true);
    try {
      final lista = await _api.consultas();
      if (state.profissionais.isEmpty) {
        try {
          final pros = await _api.profissionais();
          state = state.copyWith(profissionais: pros);
        } on ApiException {
          /* names stay blank; the appointment time still shows */
        }
      }
      state = state.copyWith(consultas: lista, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<bool> reservar({
    required String profissionalId,
    required Horario horario,
    String? sessaoId,
  }) async {
    _pendente = horario;
    _pendentePro = profissionalId;
    _pendenteSessao = sessaoId;
    state = state.copyWith(reservando: true, clearError: true);
    try {
      await _api.reservar(
        profissionalId: profissionalId,
        startsAt: horario.startsAt,
        endsAt: horario.endsAt,
        sessaoId: sessaoId,
      );
      _pendente = null;
      state = state.copyWith(reservando: false, pedindoCodigo: false);
      await carregarConsultas();
      return true;
    } on ApiException catch (e) {
      final pedeCodigo = e.code == 'identity.unverified';
      state = state.copyWith(
        reservando: false,
        pedindoCodigo: pedeCodigo,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return false;
    }
  }

  Future<bool> confirmarCodigo(String code) async {
    final horario = _pendente;
    final profissionalId = _pendentePro;
    state = state.copyWith(reservando: true, clearError: true);
    try {
      await _api.verifyEmail(code.trim());
      await ref.read(authControllerProvider.notifier).marcarEmailVerificado();
      state = state.copyWith(pedindoCodigo: false, reservando: false);
      if (horario == null || profissionalId == null) return false;
      return await reservar(
        profissionalId: profissionalId,
        horario: horario,
        sessaoId: _pendenteSessao,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        reservando: false,
        pedindoCodigo: true,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return false;
    }
  }

  Future<void> abrirReagendar(String id, String profissionalId) async {
    state = state.copyWith(reagendandoId: id, clearError: true);
    await carregarHorarios(profissionalId);
    if (state.reagendandoId != id) return;
    state = state.copyWith(reagendandoId: id);
  }

  void fecharReagendar() {
    state = state.copyWith(clearReagendar: true, horarios: const []);
  }

  Future<void> reagendar(String id, Horario horario) async {
    state = state.copyWith(reservando: true, clearError: true);
    try {
      await _api.reagendarConsulta(
        id,
        startsAt: horario.startsAt,
        endsAt: horario.endsAt,
      );
      state = state.copyWith(
        reservando: false,
        clearReagendar: true,
        horarios: const [],
      );
      await carregarConsultas();
    } on ApiException catch (e) {
      state = state.copyWith(
        reservando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> cancelar(String id) async {
    state = state.copyWith(reservando: true, clearError: true);
    try {
      await _api.cancelarConsulta(id);
      if (state.salaId == id) {
        state = state.copyWith(clearSala: true);
      }
      await carregarConsultas();
      state = state.copyWith(reservando: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        reservando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<String> entrar(String id) async {
    state = state.copyWith(reservando: true, clearError: true);
    try {
      final url = await _api.entrarVideo(id);
      state = state.copyWith(reservando: false, salaId: id);
      await carregarConsultas();
      state = state.copyWith(reservando: false, salaId: id);
      return url;
    } on ApiException catch (e) {
      state = state.copyWith(
        reservando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return '';
    }
  }

  Future<void> encerrar(String id) async {
    state = state.copyWith(reservando: true, clearError: true);
    try {
      await _api.encerrarVideo(id);
      state = state.copyWith(clearSala: true);
      await carregarConsultas();
      state = state.copyWith(reservando: false, clearSala: true);
    } on ApiException catch (e) {
      state = state.copyWith(
        reservando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> reenviarCodigo() async {
    try {
      await _api.resendVerification();
      state = state.copyWith(
        clearError: true,
        pedindoCodigo: true,
        errorMessage: 'Enviamos outro código para o seu e-mail.',
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorCode: e.code, errorMessage: e.message);
    }
  }
}

final agendaControllerProvider =
    NotifierProvider<AgendaController, AgendaSnapshot>(AgendaController.new);
