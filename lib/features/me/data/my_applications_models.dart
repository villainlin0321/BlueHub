import 'package:easy_localization/easy_localization.dart';

enum MyApplicationTabType {
  all('我的应聘.全部'),
  applied('我的应聘.已投递'),
  viewed('我的应聘.被查看'),
  interview('我的应聘.邀面试');

  const MyApplicationTabType(this.label);

  final String label;

  /// 返回“我的应聘”页 Tab 的本地化标题。
  String get localizedLabel => label.tr();
}

enum MyApplicationStatus {
  applied('我的应聘.已投递'),
  viewed('我的应聘.被查看'),
  interview('我的应聘.邀面试');

  const MyApplicationStatus(this.label);

  final String label;

  /// 返回卡片状态标签的本地化文案。
  String get localizedLabel => label.tr();
}

class MyApplicationItem {
  const MyApplicationItem({
    required this.status,
    required this.updatedText,
    required this.title,
    required this.salary,
    required this.companyName,
    required this.locationText,
    this.actionLabel = '我的应聘.联系HR',
  });

  final MyApplicationStatus status;
  final String updatedText;
  final String title;
  final String salary;
  final String companyName;
  final String locationText;
  final String actionLabel;
}
