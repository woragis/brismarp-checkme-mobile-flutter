import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/apperr/api_exception.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../identity/auth_controller.dart';

class Plano {
  const Plano({
    required this.id,
    required this.nome,
    required this.precoParcela,
    required this.parcelas,
    required this.descricaoParcela,
  });

  final String id;
  final String nome;
  final double precoParcela;
  final int parcelas;
  final String descricaoParcela;
}

class Cupom {
  const Cupom({required this.code, required this.kind, required this.value});

  final String code;
  final String kind;
  final double value;
}

class PlanosSnapshot {
  const PlanosSnapshot({
    this.planos = const [],
    this.planoAtivo = '',
    this.cupom,
    this.loading = false,
    this.contratando = false,
    this.pedindoCodigo = false,
    this.errorMessage,
    this.errorCode,
  });

  final List<Plano> planos;
  final String planoAtivo;
  final Cupom? cupom;
  final bool loading;
  final bool contratando;
  final bool pedindoCodigo;
  final String? errorMessage;
  final String? errorCode;

  PlanosSnapshot copyWith({
    List<Plano>? planos,
    String? planoAtivo,
    Cupom? cupom,
    bool clearCupom = false,
    bool? loading,
    bool? contratando,
    bool? pedindoCodigo,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return PlanosSnapshot(
      planos: planos ?? this.planos,
      planoAtivo: planoAtivo ?? this.planoAtivo,
      cupom: clearCupom ? null : (cupom ?? this.cupom),
      loading: loading ?? this.loading,
      contratando: contratando ?? this.contratando,
      pedindoCodigo: pedindoCodigo ?? this.pedindoCodigo,
      errorMessage: errorMessage ?? (clearError ? null : this.errorMessage),
      errorCode: errorCode ?? (clearError ? null : this.errorCode),
    );
  }
}

class PlanosController extends Notifier<PlanosSnapshot> {
  late final CheckmeApi _api;
  String? _pendentePlano;

  @override
  PlanosSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    return const PlanosSnapshot();
  }

  Future<void> carregar() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final lista = await _api.planos();
      var ativo = '';
      if (ref.read(authControllerProvider).user != null) {
        final eu = await _api.eu();
        ativo = _nomeAtivo(eu['subscription']);
      }
      state = state.copyWith(
        loading: false,
        planos: lista.map(_plano).toList(),
        planoAtivo: ativo,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> validar(String code) async {
    final limpo = code.trim();
    if (limpo.isEmpty) return;
    state = state.copyWith(
      contratando: true,
      clearError: true,
      clearCupom: true,
    );
    try {
      final data = await _api.validarCupom(limpo);
      state = state.copyWith(
        contratando: false,
        cupom: Cupom(
          code: data['code']?.toString() ?? limpo,
          kind: data['kind']?.toString() ?? '',
          value: (data['value'] as num?)?.toDouble() ?? 0,
        ),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        contratando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> contratar(String planId) async {
    _pendentePlano = planId;
    state = state.copyWith(contratando: true, clearError: true);
    try {
      final data = await _api.contratarPlano(
        planId: planId,
        couponCode: state.cupom?.code ?? '',
      );
      final sub = data['subscription'];
      state = state.copyWith(
        contratando: false,
        pedindoCodigo: false,
        planoAtivo: _nomeAtivo(sub),
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        contratando: false,
        pedindoCodigo: e.code == 'identity.unverified',
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<bool> confirmarCodigo(String code) async {
    final planId = _pendentePlano;
    state = state.copyWith(contratando: true, clearError: true);
    try {
      await _api.verifyEmail(code.trim());
      await ref.read(authControllerProvider.notifier).marcarEmailVerificado();
      state = state.copyWith(contratando: false, pedindoCodigo: false);
      if (planId == null) return false;
      await contratar(planId);
      return state.errorCode == null;
    } on ApiException catch (e) {
      state = state.copyWith(
        contratando: false,
        pedindoCodigo: true,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return false;
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

  Plano _plano(Map<String, dynamic> map) {
    return Plano(
      id: map['id']?.toString() ?? '',
      nome: map['nome']?.toString() ?? '',
      precoParcela: (map['precoParcela'] as num?)?.toDouble() ?? 0,
      parcelas: (map['parcelas'] as num?)?.toInt() ?? 0,
      descricaoParcela: map['descricaoParcela']?.toString() ?? '',
    );
  }

  String _nomeAtivo(dynamic raw) {
    if (raw is! Map) return '';
    final map = Map<String, dynamic>.from(raw);
    final nome = map['planNome']?.toString() ?? '';
    if (nome.isNotEmpty) return nome;
    return map['planId']?.toString() ?? '';
  }
}

final planosControllerProvider =
    NotifierProvider<PlanosController, PlanosSnapshot>(PlanosController.new);
