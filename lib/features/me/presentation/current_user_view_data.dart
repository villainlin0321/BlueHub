import 'package:easy_localization/easy_localization.dart';

import '../../auth/application/auth_user.dart';

/// 当前登录用户在“我的”相关页面里的展示态数据。
class CurrentUserViewData {
  const CurrentUserViewData({
    required this.nickname,
    required this.realNameText,
    required this.avatarUrl,
    required this.phone,
    required this.maskedPhone,
    required this.email,
    required this.emailText,
    required this.genderText,
    required this.birthdayText,
    required this.isVerified,
  });

  final String nickname;
  final String realNameText;
  final String avatarUrl;
  final String phone;
  final String maskedPhone;
  final String email;
  final String emailText;
  final String genderText;
  final String birthdayText;
  final bool isVerified;

  /// 将登录态用户信息转换成页面展示需要的稳定格式，并补齐空值兜底。
  factory CurrentUserViewData.fromAuthUser(AuthUser? user) {
    final String phone = user?.phone.trim() ?? '';
    final String nickname = user?.nickname.trim() ?? '';
    final String email = user?.email.trim() ?? '';
    final String realName = user?.realName.trim() ?? '';
    final bool isVerified = user?.isVerified ?? false;
    return CurrentUserViewData(
      nickname: nickname.isEmpty ? '我的.点击修改昵称'.tr() : nickname,
      realNameText: isVerified
          ? (realName.isEmpty ? '我的.已完成实名认证'.tr() : realName)
          : '我的.去实名'.tr(),
      avatarUrl: user?.avatarUrl.trim() ?? '',
      phone: phone,
      maskedPhone: _maskPhone(phone),
      email: email,
      emailText: email.isEmpty ? '我的.未绑定邮箱'.tr() : email,
      genderText: _formatGender(user?.gender ?? ''),
      birthdayText: _formatBirthday(user?.birthday ?? ''),
      isVerified: isVerified,
    );
  }

  /// 将服务端手机号脱敏，避免在“我的”页暴露完整号码。
  static String _maskPhone(String phone) {
    if (phone.length < 7) {
      return phone.isEmpty ? '我的.未绑定手机号'.tr() : phone;
    }
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 4)}';
  }

  /// 将服务端性别值统一转换成中文文案。
  static String _formatGender(String gender) {
    switch (gender.trim().toLowerCase()) {
      case 'male':
      case 'man':
      case 'm':
      case '1':
      case '男':
        return '我的.男'.tr();
      case 'female':
      case 'woman':
      case 'f':
      case '0':
      case '女':
        return '我的.女'.tr();
      default:
        return '我的.未填写'.tr();
    }
  }

  /// 将生日统一格式化为设计稿使用的点分隔日期格式。
  static String _formatBirthday(String birthday) {
    final String value = birthday.trim();
    if (value.isEmpty) {
      return '我的.未填写'.tr();
    }
    return value.replaceAll('-', '.').replaceAll('/', '.');
  }
}
