import '../data/auth_models.dart';
import '../../me/data/user_models.dart';

class AuthUser {
  const AuthUser({
    required this.userId,
    required this.phone,
    required this.countryCode,
    required this.email,
    required this.nickname,
    required this.avatarUrl,
    required this.role,
    required this.gender,
    required this.birthday,
    required this.currentLocation,
    required this.isVerified,
  });

  final int userId;
  final String phone;
  final String countryCode;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String role;
  final String gender;
  final String birthday;
  final String currentLocation;
  final bool isVerified;

  factory AuthUser.fromLoginUser(UserSimpleVO user) {
    return AuthUser(
      userId: user.userId,
      phone: user.phone,
      countryCode: user.countryCode,
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      role: user.role,
      gender: '',
      birthday: '',
      currentLocation: '',
      isVerified: false,
    );
  }

  factory AuthUser.fromProfile(UserVO user) {
    return AuthUser(
      userId: user.userId,
      phone: user.phone,
      countryCode: '',
      email: user.email,
      nickname: user.nickname,
      avatarUrl: user.avatarUrl,
      role: user.role,
      gender: user.gender,
      birthday: user.birthday,
      currentLocation: user.currentLocation,
      isVerified: user.isVerified,
    );
  }
}
