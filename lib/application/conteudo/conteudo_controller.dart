import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/apperr/api_exception.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../identity/auth_controller.dart';

class Desconto {
  const Desconto({
    required this.especialidade,
    required this.particular,
    required this.nossoValor,
    required this.economia,
  });

  final String especialidade;
  final String particular;
  final String nossoValor;
  final String economia;
}

class Pergunta {
  const Pergunta({required this.pergunta, required this.resposta});

  final String pergunta;
  final String resposta;
}

class ConteudoSnapshot {
  const ConteudoSnapshot({
    this.especialidades = const [],
    this.rede = const [],
    this.faq = const [],
    this.loading = false,
    this.errorMessage,
  });

  final List<String> especialidades;
  final List<Desconto> rede;
  final List<Pergunta> faq;
  final bool loading;
  final String? errorMessage;

  ConteudoSnapshot copyWith({
    List<String>? especialidades,
    List<Desconto>? rede,
    List<Pergunta>? faq,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ConteudoSnapshot(
      especialidades: especialidades ?? this.especialidades,
      rede: rede ?? this.rede,
      faq: faq ?? this.faq,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ConteudoController extends Notifier<ConteudoSnapshot> {
  late final CheckmeApi _api;

  @override
  ConteudoSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    return const ConteudoSnapshot();
  }

  Future<void> carregarEspecialidades() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final lista = await _api.especialidades();
      state = state.copyWith(loading: false, especialidades: lista);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    }
  }

  Future<void> carregarRede() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw = await _api.rede();
      state = state.copyWith(
        loading: false,
        rede: raw
            .map(
              (item) => Desconto(
                especialidade: item['especialidade']?.toString() ?? '',
                particular: item['particular']?.toString() ?? '',
                nossoValor: item['nossoValor']?.toString() ?? '',
                economia: item['economia']?.toString() ?? '',
              ),
            )
            .toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    }
  }

  Future<void> carregarFaq() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final raw = await _api.faq();
      state = state.copyWith(
        loading: false,
        faq: raw
            .map(
              (item) => Pergunta(
                pergunta: item['pergunta']?.toString() ?? '',
                resposta: item['resposta']?.toString() ?? '',
              ),
            )
            .toList(),
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    }
  }
}

final conteudoControllerProvider =
    NotifierProvider<ConteudoController, ConteudoSnapshot>(
      ConteudoController.new,
    );
