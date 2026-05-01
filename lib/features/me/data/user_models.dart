import 'package:bluehub_app/shared/network/api_decoders.dart';

class BlacklistBO {
  const BlacklistBO({required this.targetUserId, required this.action});

  final int targetUserId;
  final String action;

  factory BlacklistBO.fromJson(JsonMap json) {
    return BlacklistBO(
      targetUserId: (json['targetUserId'] as num?)?.toInt() ?? 0,
      action: json['action'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'targetUserId': targetUserId, 'action': action};
  }
}

class DeviceTokenBO {
  const DeviceTokenBO({required this.deviceToken, required this.platform});

  final String deviceToken;
  final String platform;

  factory DeviceTokenBO.fromJson(JsonMap json) {
    return DeviceTokenBO(
      deviceToken: json['deviceToken'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'deviceToken': deviceToken, 'platform': platform};
  }
}

class RealNameVerifyBO {
  const RealNameVerifyBO({
    required this.realName,
    required this.idCardNumber,
    required this.idCardFrontUrl,
    required this.idCardBackUrl,
  });

  final String realName;
  final String idCardNumber;
  final String idCardFrontUrl;
  final String idCardBackUrl;

  factory RealNameVerifyBO.fromJson(JsonMap json) {
    return RealNameVerifyBO(
      realName: json['realName'] as String? ?? '',
      idCardNumber: json['idCardNumber'] as String? ?? '',
      idCardFrontUrl: json['idCardFrontUrl'] as String? ?? '',
      idCardBackUrl: json['idCardBackUrl'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'realName': realName,
      'idCardNumber': idCardNumber,
      'idCardFrontUrl': idCardFrontUrl,
      'idCardBackUrl': idCardBackUrl,
    };
  }
}

class SwitchRoleBO {
  const SwitchRoleBO({required this.role});

  final String role;

  factory SwitchRoleBO.fromJson(JsonMap json) {
    return SwitchRoleBO(role: json['role'] as String? ?? '');
  }

  JsonMap toJson() {
    return <String, dynamic>{'role': role};
  }
}

class UpdateUserBO {
  const UpdateUserBO({
    required this.nickname,
    required this.avatarId,
    required this.gender,
    required this.birthday,
    required this.currentLocation,
  });

  final String nickname;
  final int avatarId;
  final String gender;
  final String birthday;
  final String currentLocation;

  factory UpdateUserBO.fromJson(JsonMap json) {
    return UpdateUserBO(
      nickname: json['nickname'] as String? ?? '',
      avatarId: (json['avatarId'] as num?)?.toInt() ?? 0,
      gender: json['gender'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'nickname': nickname,
      'avatarId': avatarId,
      'gender': gender,
      'birthday': birthday,
      'currentLocation': currentLocation,
    };
  }
}

class UserVO {
  const UserVO({
    required this.userId,
    required this.phone,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
    required this.gender,
    required this.birthday,
    required this.role,
    required this.currentLocation,
    required this.isVerified,
    required this.blacklistCount,
    required this.createdAt,
  });

  final int userId;
  final String phone;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String gender;
  final String birthday;
  final String role;
  final String currentLocation;
  final bool isVerified;
  final int blacklistCount;
  final String createdAt;

  factory UserVO.fromJson(JsonMap json) {
    return UserVO(
      userId: (json['userId'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      nickname: json['nickname'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      role: json['role'] as String? ?? '',
      currentLocation: json['currentLocation'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      blacklistCount: (json['blacklistCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      'phone': phone,
      'email': email,
      'nickname': nickname,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'birthday': birthday,
      'role': role,
      'currentLocation': currentLocation,
      'isVerified': isVerified,
      'blacklistCount': blacklistCount,
      'createdAt': createdAt,
    };
  }
}
