import '../../domain/agenda/models.dart';
import '../../domain/agenda/quando.dart';
import '../../domain/care/models.dart';
import '../../domain/care/visible_text.dart';
import '../../domain/identity/user.dart';
import 'api_client.dart';

class CheckmeApi {
  CheckmeApi(this._client);

  final ApiClient _client;

  Future<bool> ready() => _client.ready();

  Future<AuthTokens> register({
    required String nome,
    required String email,
    required String password,
    required bool lgpdConsent,
    String? affiliateCode,
    String? phone,
  }) async {
    final data = await _client.postJson('/auth/register', {
      'nome': nome,
      'email': email,
      'password': password,
      'lgpdConsent': lgpdConsent,
      if (affiliateCode != null && affiliateCode.isNotEmpty)
        'affiliateCode': affiliateCode,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    return _tokens(data);
  }

  Future<AuthTokens> login({
    required String email,
    required String password,
  }) async {
    final data = await _client.postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    return _tokens(data);
  }

  Future<AuthRefresh> refresh(String refreshToken) async {
    final data = await _client.postJson('/auth/refresh', {
      'refreshToken': refreshToken,
    });
    return AuthRefresh(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? refreshToken,
    );
  }

  Future<void> logout(String refreshToken) async {
    await _client.postJson('/auth/logout', {'refreshToken': refreshToken});
  }

  Future<ChatReply> chat({required String mensagem, String? sessaoId}) async {
    final data = await _client.postJson('/chat', {
      'mensagem': mensagem,
      if (sessaoId != null && sessaoId.isNotEmpty) 'sessaoId': sessaoId,
    });
    return ChatReply(
      status: TriageStatus.parse(data['status']?.toString()),
      mensagem: visibleOrientationText(data['mensagem']?.toString()),
      sessaoId: data['sessaoId']?.toString() ?? '',
      soap: data['soap']?.toString(),
    );
  }

  Future<List<SessionView>> listTriagens() async {
    final raw = await _client.getList('/me/triagens');
    return raw
        .whereType<Map>()
        .map((m) => _session(Map<String, dynamic>.from(m), withHistory: false))
        .toList();
  }

  Future<SessionView> triagem(String id) async {
    final data = await _client.getJson('/me/triagens/$id');
    return _session(data, withHistory: true);
  }

  Future<void> verifyEmail(String code) async {
    await _client.postJson('/auth/verify-email', {'code': code});
  }

  Future<void> resendVerification() async {
    await _client.postJson('/auth/resend-verification', {});
  }

  Future<List<Profissional>> profissionais() async {
    final raw = await _client.getList('/professionals');
    final agora = DateTime.now();
    final lista = <Profissional>[];
    for (final item in raw.whereType<Map>()) {
      final map = Map<String, dynamic>.from(item);
      final id = map['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      DateTime? proximo;
      try {
        final slots = await horarios(id);
        proximo = proximoFuturo(slots.map((s) => s.startsAt), agora);
      } catch (_) {
        proximo = null;
      }
      lista.add(
        Profissional(
          id: id,
          nome: map['nome']?.toString() ?? '',
          especialidade: map['specialties']?.toString() ?? '',
          proximo: proximo,
        ),
      );
    }
    return lista;
  }

  Future<List<Horario>> horarios(String profissionalId) async {
    final raw = await _client.getList('/professionals/$profissionalId/slots');
    return raw.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      return Horario(
        id: map['id']?.toString() ?? '',
        startsAt:
            DateTime.tryParse(map['startsAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        endsAt:
            DateTime.tryParse(map['endsAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );
    }).toList();
  }

  Future<Consulta> reservar({
    required String profissionalId,
    required DateTime startsAt,
    required DateTime endsAt,
    String? sessaoId,
  }) async {
    final data = await _client.postJson('/appointments', {
      'professionalId': profissionalId,
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
      if (sessaoId != null && sessaoId.isNotEmpty) 'sessaoId': sessaoId,
    });
    return _consulta(data);
  }

  Future<List<Consulta>> consultas() async {
    final raw = await _client.getList('/appointments');
    return raw
        .whereType<Map>()
        .map((item) => _consulta(Map<String, dynamic>.from(item)))
        .toList();
  }

  Consulta _consulta(Map<String, dynamic> data) {
    return Consulta(
      id: data['id']?.toString() ?? '',
      profissionalId: data['professionalId']?.toString() ?? '',
      startsAt:
          DateTime.tryParse(data['startsAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: data['status']?.toString() ?? '',
      videoStatus: data['videoStatus']?.toString() ?? '',
    );
  }

  Future<void> reagendarConsulta(
    String id, {
    required DateTime startsAt,
    required DateTime endsAt,
  }) async {
    await _client.postJson('/appointments/$id/reschedule', {
      'startsAt': startsAt.toUtc().toIso8601String(),
      'endsAt': endsAt.toUtc().toIso8601String(),
    });
  }

  Future<void> cancelarConsulta(String id) async {
    await _client.postJson('/appointments/$id/cancel', {});
  }

  Future<String> entrarVideo(String id) async {
    final data = await _client.postJson('/appointments/$id/video/join', {});
    return data['url']?.toString() ?? '';
  }

  Future<void> encerrarVideo(String id) async {
    await _client.postJson('/appointments/$id/video/end', {});
  }

  Future<Map<String, dynamic>> eu() => _client.getJson('/me');

  Future<Map<String, dynamic>> atualizarEu({
    required String nome,
    required String cpf,
    required String phone,
  }) {
    return _client.patchJson('/me', {'nome': nome, 'cpf': cpf, 'phone': phone});
  }

  Future<Map<String, dynamic>> exportarEu() => _client.getJson('/me/export');

  Future<void> apagarEu() async {
    await _client.postJson('/me/erase', {});
  }

  Future<Map<String, dynamic>> adicionarDependente({
    required String nome,
    required String kinship,
  }) {
    return _client.postJson('/me/dependents', {
      'nome': nome,
      'kinship': kinship,
    });
  }

  Future<void> removerDependente(String id) async {
    await _client.delete('/me/dependents/$id');
  }

  Future<List<Map<String, dynamic>>> planos() async {
    final raw = await _client.getList('/planos');
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> validarCupom(String code) {
    return _client.postJson('/coupons/validate', {'code': code});
  }

  Future<Map<String, dynamic>> contratarPlano({
    required String planId,
    String couponCode = '',
  }) {
    return _client.postJson('/subscriptions', {
      'planId': planId,
      if (couponCode.isNotEmpty) 'couponCode': couponCode,
    });
  }

  Future<void> esqueciSenha(String email) async {
    await _client.postJson('/auth/forgot-password', {'email': email});
  }

  Future<void> redefinirSenha({
    required String email,
    required String code,
    required String password,
  }) async {
    await _client.postJson('/auth/reset-password', {
      'email': email,
      'code': code,
      'password': password,
    });
  }

  Future<List<String>> especialidades() async {
    final raw = await _client.getList('/especialidades');
    return raw
        .map((item) => item.toString())
        .where((n) => n.isNotEmpty)
        .toList();
  }

  Future<List<Map<String, dynamic>>> rede() async {
    final raw = await _client.getList('/rede-credenciada/descontos');
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<List<Map<String, dynamic>>> faq() async {
    final raw = await _client.getList('/faq');
    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<ContactInfo> contato() async {
    final data = await _client.getJson('/contato');
    return ContactInfo(whatsapp: data['whatsapp']?.toString());
  }

  AuthTokens _tokens(Map<String, dynamic> data) {
    final userRaw = data['user'];
    final userMap = userRaw is Map
        ? Map<String, dynamic>.from(userRaw)
        : <String, dynamic>{};
    return AuthTokens(
      accessToken: data['accessToken']?.toString() ?? '',
      refreshToken: data['refreshToken']?.toString() ?? '',
      user: User.fromJson(userMap),
    );
  }

  SessionView _session(Map<String, dynamic> data, {required bool withHistory}) {
    final history = <CareMessage>[];
    if (withHistory) {
      final raw = data['history'];
      if (raw is List) {
        var i = 0;
        for (final item in raw) {
          if (item is! Map) continue;
          final role = item['role']?.toString() ?? '';
          final content = item['content']?.toString() ?? '';
          final text = visibleOrientationText(content);
          if (text.isEmpty && looksLikeSoapJson(content)) continue;
          if (text.isEmpty) continue;
          history.add(
            CareMessage(
              id: 'h-$i',
              text: text,
              fromUser: role == 'user',
              at: DateTime.now(),
            ),
          );
          i += 1;
        }
      }
    }
    return SessionView(
      id: data['id']?.toString() ?? '',
      status: TriageStatus.parse(data['status']?.toString()),
      history: history,
      soap: data['soap']?.toString(),
      updatedAt: DateTime.tryParse(data['updatedAt']?.toString() ?? ''),
    );
  }
}
