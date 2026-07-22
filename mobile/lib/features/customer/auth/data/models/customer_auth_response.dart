class CustomerAuthResponse {
  const CustomerAuthResponse({
    required this.token,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userType,
    required this.requiresLegalOnboarding,
    this.userPhone,
    this.birthDate,
  });

  final String token;
  final int userId;
  final String userName;
  final String userEmail;
  final String userType;
  final bool requiresLegalOnboarding;
  final String? userPhone;
  final String? birthDate;

  factory CustomerAuthResponse.fromJson(Map<String, dynamic> json) {
    final user = json['user'];

    if (user is! Map<String, dynamic>) {
      throw const FormatException(
        'El servidor respondió con datos de usuario inválidos.',
      );
    }

    return CustomerAuthResponse(
      token: json['token']?.toString() ?? '',
      userId: _parseUserId(user['id']),
      userName: user['name']?.toString() ?? '',
      userEmail: user['email']?.toString() ?? '',
      userType: user['type']?.toString() ?? '',
      userPhone: user['phone']?.toString(),
      birthDate: user['birth_date']?.toString(),
      requiresLegalOnboarding: json['requires_legal_onboarding'] == true,
    );
  }

  static int _parseUserId(dynamic value) {
    if (value is int) {
      return value;
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw const FormatException(
        'El servidor respondió con un identificador de usuario inválido.',
      );
    }

    return parsed;
  }
}
