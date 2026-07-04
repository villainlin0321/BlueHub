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
      'editVisaPackage': PatrolRouteMatcher(
        routePath: RoutePaths.editVisaPackage,
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
        fallbackText: '资质认证',
      ),
      'settings': PatrolRouteMatcher(
        routePath: RoutePaths.settings,
        fallbackText: '设置',
      ),
    };
