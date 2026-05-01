import 'package:bluehub_app/shared/network/api_decoders.dart';

class EmailLoginBO {
  const EmailLoginBO({
    required this.email,
    required this.password,
    required this.code,
  });

  final String email;
  final String password;
  final String code;

  factory EmailLoginBO.fromJson(JsonMap json) {
    return EmailLoginBO(
      email: json['email'] as String? ?? '',
      password: json['password'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'code': code,
    };
  }
}

class LoginVO {
  const LoginVO({
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
  final UserSimpleVO user;

  factory LoginVO.fromJson(JsonMap json) {
    return LoginVO(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
      isNewUser: json['isNewUser'] as bool? ?? false,
      needSelectRole: json['needSelectRole'] as bool? ?? false,
      user: UserSimpleVO.fromJson(
        asJsonMap(json['user'] ?? const <String, dynamic>{}),
      ),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'isNewUser': isNewUser,
      'needSelectRole': needSelectRole,
      'user': user.toJson(),
    };
  }
}

class OauthLoginBO {
  const OauthLoginBO({
    required this.provider,
    required this.authCode,
    required this.platform,
  });

  final String provider;
  final String authCode;
  final String platform;

  factory OauthLoginBO.fromJson(JsonMap json) {
    return OauthLoginBO(
      provider: json['provider'] as String? ?? '',
      authCode: json['authCode'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'provider': provider,
      'authCode': authCode,
      'platform': platform,
    };
  }
}

class PhoneLoginBO {
  const PhoneLoginBO({
    required this.phone,
    required this.countryCode,
    required this.code,
  });

  final String phone;
  final String countryCode;
  final String code;

  factory PhoneLoginBO.fromJson(JsonMap json) {
    return PhoneLoginBO(
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'phone': phone,
      'countryCode': countryCode,
      'code': code,
    };
  }
}

class RefreshTokenBO {
  const RefreshTokenBO({required this.refreshToken});

  final String refreshToken;

  factory RefreshTokenBO.fromJson(JsonMap json) {
    return RefreshTokenBO(refreshToken: json['refreshToken'] as String? ?? '');
  }

  JsonMap toJson() {
    return <String, dynamic>{'refreshToken': refreshToken};
  }
}

class SelectRoleBO {
  const SelectRoleBO({required this.role});

  final String role;

  factory SelectRoleBO.fromJson(JsonMap json) {
    return SelectRoleBO(role: json['role'] as String? ?? '');
  }

  JsonMap toJson() {
    return <String, dynamic>{'role': role};
  }
}

class SendEmailBO {
  const SendEmailBO({required this.email, required this.scene});

  final String email;
  final String scene;

  factory SendEmailBO.fromJson(JsonMap json) {
    return SendEmailBO(
      email: json['email'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'email': email, 'scene': scene};
  }
}

class SendSmsBO {
  const SendSmsBO({
    required this.phone,
    required this.countryCode,
    required this.scene,
  });

  final String phone;
  final String countryCode;
  final String scene;

  factory SendSmsBO.fromJson(JsonMap json) {
    return SendSmsBO(
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      scene: json['scene'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'phone': phone,
      'countryCode': countryCode,
      'scene': scene,
    };
  }
}

class UserSimpleVO {
  const UserSimpleVO({
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

  factory UserSimpleVO.fromJson(JsonMap json) {
    return UserSimpleVO(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      role: json['role'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'phone': phone,
      'countryCode': countryCode,
      'role': role,
      'avatarUrl': avatarUrl,
      'nickname': nickname,
      'email': email,
    };
  }
}
