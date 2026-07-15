import 'package:europepass/app/router/route_paths.dart';
import 'package:europepass/shared/ui/test_keys.dart';

import '../helpers/patrol_route_matcher.dart';

/// 汇总服务商 Task3 验收涉及的页面锚点定义，统一复用稳定 Key 与兜底文案。
const Map<String, PatrolRouteMatcher> serviceProviderRouteMatchers =
    <String, PatrolRouteMatcher>{
      'home': PatrolRouteMatcher(
        routePath: RoutePaths.home,
        readyKey: AppTestKeys.pageServiceProviderHome,
        fallbackText: '首页',
      ),
      'jobs': PatrolRouteMatcher(
        routePath: RoutePaths.jobs,
        readyKey: AppTestKeys.pageServiceProviderJobs,
        fallbackText: '套餐管理',
      ),
      'editVisaPackage': PatrolRouteMatcher(
        routePath: RoutePaths.editVisaPackage,
        readyKey: AppTestKeys.pageEditVisaPackage,
        fallbackText: '编辑套餐',
      ),
      'orderManagement': PatrolRouteMatcher(
        routePath: RoutePaths.orderManagement,
        fallbackText: '订单管理',
      ),
      'talentCenter': PatrolRouteMatcher(
        routePath: RoutePaths.serviceProviderTalentCenter,
        fallbackText: '人才中心',
      ),
      'financeSettlement': PatrolRouteMatcher(
        routePath: RoutePaths.financeSettlement,
        fallbackText: '财务结算',
      ),
      'me': PatrolRouteMatcher(
        routePath: RoutePaths.me,
        readyKey: AppTestKeys.pageServiceProviderMe,
        fallbackText: '我的',
      ),
      'qualificationCertification': PatrolRouteMatcher(
        routePath: RoutePaths.qualificationCertification,
        readyKey: AppTestKeys.pageQualificationCertificationStepOne,
        fallbackText: '资质认证',
      ),
      'qualificationCertificationStepTwo': PatrolRouteMatcher(
        routePath: RoutePaths.qualificationCertificationStepTwo,
        readyKey: AppTestKeys.pageQualificationCertificationStepTwo,
        fallbackText: '资质认证',
      ),
      'qualificationCertificationStepThree': PatrolRouteMatcher(
        routePath: RoutePaths.qualificationCertificationStepThree,
        readyKey: AppTestKeys.pageQualificationCertificationStepThree,
        fallbackText: '资质认证',
      ),
      'qualificationCertificationResult': PatrolRouteMatcher(
        routePath: RoutePaths.appResult,
        readyKey: AppTestKeys.pageQualificationCertificationResult,
        fallbackText: '信息已提交',
      ),
      'settings': PatrolRouteMatcher(
        routePath: RoutePaths.settings,
        fallbackText: '设置',
      ),
      'visa': PatrolRouteMatcher(
        routePath: RoutePaths.visa,
        readyKey: AppTestKeys.pageServiceProviderVisa,
        fallbackText: '订单',
      ),
      'orderDetail': PatrolRouteMatcher(
        routePath: RoutePaths.orderDetail,
        fallbackText: '订单详情',
      ),
      'chat': PatrolRouteMatcher(
        routePath: RoutePaths.chat,
        fallbackText: '聊天',
      ),
    };
