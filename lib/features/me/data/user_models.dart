import 'package:bluehub_app/shared/network/api_decoders.dart';

class BlacklistBO {
  const BlacklistBO({required this.targetUserId, required this.action});

  final int targetUserId;
  final String action;

  factory BlacklistBO.fromJson(JsonMap json) {
    return BlacklistBO(
      targetUserId: readInt(json, 'targetUserId'),
      action: readString(json, 'action'),
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
      deviceToken: readString(json, 'deviceToken'),
      platform: readString(json, 'platform'),
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
      realName: readString(json, 'realName'),
      idCardNumber: readString(json, 'idCardNumber'),
      idCardFrontUrl: readString(json, 'idCardFrontUrl'),
      idCardBackUrl: readString(json, 'idCardBackUrl'),
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
    return SwitchRoleBO(role: readString(json, 'role'));
  }

  JsonMap toJson() {
    return <String, dynamic>{'role': role};
  }
}

class UpdateUserBO {
  const UpdateUserBO({
    this.nickname,
    this.avatarId,
    this.gender,
    this.birthday,
    this.currentLocation,
  });

  final String? nickname;
  final int? avatarId;
  final String? gender;
  final String? birthday;
  final String? currentLocation;

  factory UpdateUserBO.fromJson(JsonMap json) {
    return UpdateUserBO(
      nickname: json.containsKey('nickname')
          ? readString(json, 'nickname')
          : null,
      avatarId: json.containsKey('avatarId') ? readInt(json, 'avatarId') : null,
      gender: json.containsKey('gender') ? readString(json, 'gender') : null,
      birthday: json.containsKey('birthday')
          ? readString(json, 'birthday')
          : null,
      currentLocation: json.containsKey('currentLocation')
          ? readString(json, 'currentLocation')
          : null,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      if (nickname != null) 'nickname': nickname,
      if (avatarId != null) 'avatarId': avatarId,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
      if (currentLocation != null) 'currentLocation': currentLocation,
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
      userId: readInt(json, 'userId'),
      phone: readString(json, 'phone'),
      email: readString(json, 'email'),
      nickname: readString(json, 'nickname'),
      avatarUrl: readString(json, 'avatarUrl'),
      gender: readString(json, 'gender'),
      birthday: readString(json, 'birthday'),
      role: readString(json, 'role'),
      currentLocation: readString(json, 'currentLocation'),
      isVerified: readBool(json, 'isVerified'),
      blacklistCount: readInt(json, 'blacklistCount'),
      createdAt: readString(json, 'createdAt'),
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
