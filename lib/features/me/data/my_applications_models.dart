enum MyApplicationTabType {
  all('全部'),
  applied('已投递'),
  viewed('被查看'),
  interview('邀面试');

  const MyApplicationTabType(this.label);

  final String label;
}

enum MyApplicationStatus {
  applied('已投递'),
  viewed('被查看'),
  interview('邀面试');

  const MyApplicationStatus(this.label);

  final String label;
}

class MyApplicationItem {
  const MyApplicationItem({
    required this.status,
    required this.updatedText,
    required this.title,
    required this.salary,
    required this.companyName,
    required this.locationText,
    this.actionLabel = '联系HR',
  });

  final MyApplicationStatus status;
  final String updatedText;
  final String title;
  final String salary;
  final String companyName;
  final String locationText;
  final String actionLabel;
}
