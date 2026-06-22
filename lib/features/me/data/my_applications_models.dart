import 'package:easy_localization/easy_localization.dart';

import '../../../shared/models/app_currency.dart';
import '../../jobs/data/application_models.dart';

enum MyApplicationTabType {
  all('我的应聘.全部', apiStatus: 'all'),
  applied('我的应聘.已投递', apiStatus: 'submitted'),
  viewed('我的应聘.被查看', apiStatus: 'viewed'),
  interview('我的应聘.邀面试', apiStatus: 'interview');

  const MyApplicationTabType(this.label, {required this.apiStatus});

  final String label;
  final String apiStatus;

  /// 返回“我的应聘”页 Tab 的本地化标题。
  String get localizedLabel => label.tr();
}

enum MyApplicationStatus {
  applied('我的应聘.已投递', apiStatus: 'submitted'),
  viewed('我的应聘.被查看', apiStatus: 'viewed'),
  interview('我的应聘.邀面试', apiStatus: 'interview');

  const MyApplicationStatus(this.label, {required this.apiStatus});

  final String label;
  final String apiStatus;

  /// 返回卡片状态标签的本地化文案。
  String get localizedLabel => label.tr();

  factory MyApplicationStatus.fromApiStatus(String rawStatus) {
    final String normalized = rawStatus.trim().toLowerCase();
    return MyApplicationStatus.values.firstWhere(
      (MyApplicationStatus status) => status.apiStatus == normalized,
      orElse: () => MyApplicationStatus.applied,
    );
  }
}

class MyApplicationItem {
  const MyApplicationItem({
    required this.applicationId,
    required this.profileId,
    required this.status,
    required this.updatedText,
    required this.title,
    required this.salary,
    required this.companyName,
    required this.locationText,
    this.actionLabel = '我的应聘.联系HR',
  });

  final int applicationId;
  final int? profileId;
  final MyApplicationStatus status;
  final String updatedText;
  final String title;
  final String salary;
  final String companyName;
  final String locationText;
  final String actionLabel;

  factory MyApplicationItem.fromApplication(ApplicationVO application) {
    return MyApplicationItem(
      applicationId: application.applicationId,
      profileId: application.employer.profileId,
      status: MyApplicationStatus.fromApiStatus(application.status),
      updatedText: _formatUpdatedText(
        application.updatedAt,
        fallback: application.submittedAt,
      ),
      title: application.job.title.trim(),
      salary: _formatSalary(application.job),
      companyName: application.employer.name.trim(),
      locationText: '',
    );
  }
}

String _formatSalary(JobSimpleVO job) {
  final double min = job.salaryMin;
  final double max = job.salaryMax;
  if (min <= 0 && max <= 0) {
    return '暂无'.tr();
  }

  return AppCurrency.formatRange(
    min: min,
    max: max,
    rawCurrency: job.salaryCurrency,
  );
}

String _formatUpdatedText(String raw, {required String fallback}) {
  final String effective = raw.trim().isNotEmpty ? raw.trim() : fallback.trim();
  final DateTime? parsed = DateTime.tryParse(effective)?.toLocal();
  if (parsed == null) {
    return effective;
  }

  final String year = parsed.year.toString().padLeft(4, '0');
  final String month = parsed.month.toString().padLeft(2, '0');
  final String day = parsed.day.toString().padLeft(2, '0');
  final String hour = parsed.hour.toString().padLeft(2, '0');
  final String minute = parsed.minute.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute';
}
