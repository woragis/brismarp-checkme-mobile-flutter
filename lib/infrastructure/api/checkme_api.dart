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
