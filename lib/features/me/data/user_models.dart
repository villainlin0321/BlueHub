import 'package:europepass/shared/network/api_decoders.dart';

class BlacklistBO {
  const BlacklistBO({
    required this.targetUserId,
    required this.action,
    this.targetRole,
  });

  final int targetUserId;
  final String action;
  final String? targetRole;

  factory BlacklistBO.fromJson(JsonMap json) {
    return BlacklistBO(
      targetUserId: readInt(json, 'targetUserId'),
      action: readString(json, 'action'),
      targetRole: json.containsKey('targetRole')
          ? readString(json, 'targetRole')
          : null,
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'targetUserId': targetUserId,
      'action': action,
      if (targetRole != null) 'targetRole': targetRole,
    };
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

class BindPhoneBO {
  const BindPhoneBO({
    required this.phone,
    required this.countryCode,
    required this.code,
  });

  final String phone;
  final String countryCode;
  final String code;

  factory BindPhoneBO.fromJson(JsonMap json) {
    return BindPhoneBO(
      phone: readString(json, 'phone'),
      countryCode: readString(json, 'countryCode'),
      code: readString(json, 'code'),
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

class BindEmailBO {
  const BindEmailBO({required this.email, required this.code});

  final String email;
  final String code;

  factory BindEmailBO.fromJson(JsonMap json) {
    return BindEmailBO(
      email: readString(json, 'email'),
      code: readString(json, 'code'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{'email': email, 'code': code};
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

class RealNameVerificationVO {
  const RealNameVerificationVO({
    required this.verifyId,
    required this.realName,
    required this.idCardNumber,
    required this.idCardFront,
    required this.idCardBack,
    required this.status,
    required this.statusLabel,
    required this.rejectReason,
    required this.createdAt,
    required this.reviewedAt,
    required this.updatedAt,
  });

  final int verifyId;
  final String realName;
  final String idCardNumber;
  final String idCardFront;
  final String idCardBack;
  final String status;
  final String statusLabel;
  final String rejectReason;
  final String createdAt;
  final String reviewedAt;
  final String updatedAt;

  factory RealNameVerificationVO.fromJson(JsonMap json) {
    return RealNameVerificationVO(
      verifyId: readInt(json, 'verifyId'),
      realName: readString(json, 'realName'),
      idCardNumber: readString(json, 'idCardNumber'),
      idCardFront: readString(json, 'idCardFront'),
      idCardBack: readString(json, 'idCardBack'),
      status: readString(json, 'status'),
      statusLabel: readString(json, 'statusLabel'),
      rejectReason: readString(json, 'rejectReason'),
      createdAt: readString(json, 'createdAt'),
      reviewedAt: readString(json, 'reviewedAt'),
      updatedAt: readString(json, 'updatedAt'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'verifyId': verifyId,
      'realName': realName,
      'idCardNumber': idCardNumber,
      'idCardFront': idCardFront,
      'idCardBack': idCardBack,
      'status': status,
      'statusLabel': statusLabel,
      'rejectReason': rejectReason,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
      'updatedAt': updatedAt,
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
    this.realName = '',
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
  final String realName;
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
      realName: readString(json, 'realName'),
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
      'realName': realName,
      'blacklistCount': blacklistCount,
      'createdAt': createdAt,
    };
  }
}

class BlacklistItemVO {
  const BlacklistItemVO({
    required this.userId,
    this.profileId,
    required this.role,
    required this.name,
    required this.avatarUrl,
  });

  final int userId;
  final int? profileId;
  final String role;
  final String name;
  final String avatarUrl;

  factory BlacklistItemVO.fromJson(JsonMap json) {
    return BlacklistItemVO(
      userId: readInt(json, 'userId'),
      profileId: json.containsKey('profileId') ? readInt(json, 'profileId') : null,
      role: readString(json, 'role'),
      name: readString(json, 'name'),
      avatarUrl: readString(json, 'avatarUrl'),
    );
  }

  JsonMap toJson() {
    return <String, dynamic>{
      'userId': userId,
      if (profileId != null) 'profileId': profileId,
      'role': role,
      'name': name,
      'avatarUrl': avatarUrl,
    };
  }
}
