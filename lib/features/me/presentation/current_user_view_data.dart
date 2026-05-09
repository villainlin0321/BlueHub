import '../../auth/application/auth_user.dart';

/// 当前登录用户在“我的”相关页面里的展示态数据。
class CurrentUserViewData {
  const CurrentUserViewData({
    required this.nickname,
    required this.avatarUrl,
    required this.phone,
    required this.maskedPhone,
    required this.genderText,
    required this.birthdayText,
    required this.isVerified,
  });

  final String nickname;
  final String avatarUrl;
  final String phone;
  final String maskedPhone;
  final String genderText;
  final String birthdayText;
  final bool isVerified;

  /// 将登录态用户信息转换成页面展示需要的稳定格式，并补齐空值兜底。
  factory CurrentUserViewData.fromAuthUser(AuthUser? user) {
    final String phone = user?.phone.trim() ?? '';
    final String nickname = user?.nickname.trim() ?? '';
    return CurrentUserViewData(
      nickname: nickname.isEmpty ? '未设置昵称' : nickname,
      avatarUrl: user?.avatarUrl.trim() ?? '',
      phone: phone,
      maskedPhone: _maskPhone(phone),
      genderText: _formatGender(user?.gender ?? ''),
      birthdayText: _formatBirthday(user?.birthday ?? ''),
      isVerified: user?.isVerified ?? false,
    );
  }

  /// 将服务端手机号脱敏，避免在“我的”页暴露完整号码。
  static String _maskPhone(String phone) {
    if (phone.length < 7) {
      return phone.isEmpty ? '未绑定手机号' : phone;
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
        return '男';
      case 'female':
      case 'woman':
      case 'f':
      case '0':
      case '女':
        return '女';
      default:
        return '未填写';
    }
  }

  /// 将生日统一格式化为设计稿使用的点分隔日期格式。
  static String _formatBirthday(String birthday) {
    final String value = birthday.trim();
    if (value.isEmpty) {
      return '未填写';
    }
    return value.replaceAll('-', '.').replaceAll('/', '.');
  }
}
