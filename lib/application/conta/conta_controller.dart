import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/apperr/api_exception.dart';
import '../../infrastructure/api/checkme_api.dart';
import '../identity/auth_controller.dart';

class Dependente {
  const Dependente({
    required this.id,
    required this.nome,
    required this.kinship,
  });

  final String id;
  final String nome;
  final String kinship;
}

class ContaSnapshot {
  const ContaSnapshot({
    this.cpf = '',
    this.phone = '',
    this.dependentes = const [],
    this.loading = false,
    this.salvando = false,
    this.errorMessage,
    this.errorCode,
  });

  final String cpf;
  final String phone;
  final List<Dependente> dependentes;
  final bool loading;
  final bool salvando;
  final String? errorMessage;
  final String? errorCode;

  ContaSnapshot copyWith({
    String? cpf,
    String? phone,
    List<Dependente>? dependentes,
    bool? loading,
    bool? salvando,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return ContaSnapshot(
      cpf: cpf ?? this.cpf,
      phone: phone ?? this.phone,
      dependentes: dependentes ?? this.dependentes,
      loading: loading ?? this.loading,
      salvando: salvando ?? this.salvando,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }
}

class ContaController extends Notifier<ContaSnapshot> {
  late final CheckmeApi _api;

  @override
  ContaSnapshot build() {
    _api = ref.read(checkmeApiProvider);
    return const ContaSnapshot();
  }

  Future<void> carregar() async {
    if (ref.read(authControllerProvider).user == null) return;
    state = state.copyWith(loading: true, clearError: true);
    try {
      final data = await _api.eu();
      state = state.copyWith(
        loading: false,
        cpf: data['cpf']?.toString() ?? '',
        phone: data['phone']?.toString() ?? '',
        dependentes: _dependentes(data['dependents']),
      );
      final nome = data['nome']?.toString() ?? '';
      if (nome.isNotEmpty) {
        await ref.read(authControllerProvider.notifier).atualizarNome(nome);
      }
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<bool> salvar({
    required String nome,
    required String cpf,
    required String phone,
  }) async {
    state = state.copyWith(salvando: true, clearError: true);
    try {
      final data = await _api.atualizarEu(
        nome: nome.trim(),
        cpf: cpf.trim(),
        phone: phone.trim(),
      );
      state = state.copyWith(
        salvando: false,
        cpf: data['cpf']?.toString() ?? cpf.trim(),
        phone: data['phone']?.toString() ?? phone.trim(),
        dependentes: _dependentes(data['dependents']),
      );
      await ref
          .read(authControllerProvider.notifier)
          .atualizarNome(data['nome']?.toString() ?? nome);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        salvando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return false;
    }
  }

  Future<void> adicionar({
    required String nome,
    required String kinship,
  }) async {
    state = state.copyWith(salvando: true, clearError: true);
    try {
      await _api.adicionarDependente(
        nome: nome.trim(),
        kinship: kinship.trim(),
      );
      state = state.copyWith(salvando: false);
      await carregar();
    } on ApiException catch (e) {
      state = state.copyWith(
        salvando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<void> remover(String id) async {
    state = state.copyWith(salvando: true, clearError: true);
    try {
      await _api.removerDependente(id);
      state = state.copyWith(salvando: false);
      await carregar();
    } on ApiException catch (e) {
      state = state.copyWith(
        salvando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
    }
  }

  Future<String?> exportar() async {
    state = state.copyWith(clearError: true);
    try {
      final data = await _api.exportarEu();
      return const JsonEncoder.withIndent('  ').convert(data);
    } on ApiException catch (e) {
      state = state.copyWith(errorCode: e.code, errorMessage: e.message);
      return null;
    }
  }

  Future<bool> apagar() async {
    state = state.copyWith(salvando: true, clearError: true);
    try {
      await _api.apagarEu();
      await ref.read(authControllerProvider.notifier).clearLocal();
      state = const ContaSnapshot();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        salvando: false,
        errorCode: e.code,
        errorMessage: e.message,
      );
      return false;
    }
  }

  List<Dependente> _dependentes(dynamic raw) {
    if (raw is! List) return const [];
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return Dependente(
        id: map['id']?.toString() ?? '',
        nome: map['nome']?.toString() ?? '',
        kinship: map['kinship']?.toString() ?? '',
      );
    }).toList();
  }
}

final contaControllerProvider =
    NotifierProvider<ContaController, ContaSnapshot>(ContaController.new);
