class User {
  const User({
    required this.id,
    required this.email,
    required this.nome,
    this.role,
    this.emailVerified = false,
  });

  final String id;
  final String email;
  final String nome;
  final String? role;
  final bool emailVerified;

  String get primeiroNome {
    final parts = nome.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? nome : parts.first;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nome': nome,
        'role': role,
        'emailVerified': emailVerified,
      };

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      role: json['role']?.toString(),
      emailVerified: json['emailVerified'] == true,
    );
  }
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final User user;
}
