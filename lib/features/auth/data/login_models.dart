class PhoneLoginRequest {
  const PhoneLoginRequest({
    required this.phone,
    required this.countryCode,
    required this.code,
  });

  final String phone;
  final String countryCode;
  final String code;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'phone': phone,
      'countryCode': countryCode,
      'code': code,
    };
  }
}

class LoginResponse {
  const LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.isNewUser,
    required this.needSelectRole,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final bool isNewUser;
  final bool needSelectRole;
  final UserSimple user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      isNewUser: json['isNewUser'] as bool? ?? false,
      needSelectRole: json['needSelectRole'] as bool? ?? false,
      user: UserSimple.fromJson((json['user'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{}),
    );
  }
}

class UserSimple {
  const UserSimple({
    required this.userId,
    required this.phone,
    required this.countryCode,
    required this.role,
    required this.avatarUrl,
    required this.nickname,
    required this.email,
  });

  final int userId;
  final String phone;
  final String countryCode;
  final String role;
  final String avatarUrl;
  final String nickname;
  final String email;

  factory UserSimple.fromJson(Map<String, dynamic> json) {
    return UserSimple(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      role: json['role'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }
}

