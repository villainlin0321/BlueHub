import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../../features/auth/presentation/login_phone_page.dart';
import '../../features/auth/presentation/qualification_certification_page.dart';
import '../../features/auth/presentation/qualification_certification_step_three_page.dart';
import '../../features/auth/presentation/qualification_certification_step_two_page.dart';
import '../../features/auth/select_role/presentation/select_role_page.dart';
import '../../features/ai/presentation/ai_assistant_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jobs/presentation/company_application_management_page.dart';
import '../../features/jobs/presentation/job_detail_page.dart';
import '../../features/jobs/presentation/jobs_page.dart';
import '../../features/jobs/presentation/post_job_page.dart';
import '../../features/me/presentation/me_page.dart';
import '../../features/me/presentation/add_education_experience_page.dart';
import '../../features/me/presentation/add_education_school_page.dart';
import '../../features/me/presentation/add_work_experience_page.dart';
import '../../features/me/presentation/add_skill_certificate_page.dart';
import '../../features/me/presentation/my_applications_page.dart';
import '../../features/me/presentation/my_favorites_page.dart';
import '../../features/me/presentation/my_info_page.dart';
import '../../features/me/presentation/my_resume_editor_page.dart';
import '../../features/me/presentation/my_resume_page.dart';
import '../../features/me/presentation/my_resume_preview_page.dart';
import '../../features/me/presentation/settings_page.dart';
import '../../features/order/presentation/order_detail_page.dart';
import '../../features/order/presentation/order_review_page.dart';
import '../../features/me/presentation/self_evaluation_page.dart';
import '../../features/service_detail/presentation/app_result_page.dart';
import '../../features/service_detail/presentation/service_detail_page.dart';
import '../../features/service_detail/presentation/service_detail_report_page.dart';
import '../../features/me/presentation/my_orders_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/visa/presentation/edit_visa_package_page.dart';
import '../../features/visa/presentation/visa_page.dart';
import '../../shared/logging/app_logger.dart';
import 'route_paths.dart';

/// 提供全局 `GoRouter` 实例，并在关键路由变化时输出日志。
final routerProvider = Provider<GoRouter>((ref) {
  final authSession = ref.watch(authSessionProvider);

  final router = GoRouter(
    initialLocation: RoutePaths.loginPhone,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoginRoute = location == RoutePaths.loginPhone;
      final isSelectRoleRoute = location == RoutePaths.selectRole;
      final isAuthRoute = isLoginRoute || isSelectRoleRoute;

      if (authSession.isHydrating) {
        AppLogger.instance.debug(
          'ROUTE',
          '会话恢复中，暂不拦截路由',
          context: <String, Object?>{'location': location},
        );
        return null;
      }

      if (!authSession.isAuthenticated) {
        if (isLoginRoute) {
          return null;
        }
        AppLogger.instance.warn(
          'ROUTE',
          '未登录，跳转到登录页',
          context: <String, Object?>{
            'from': location,
            'to': RoutePaths.loginPhone,
          },
        );
        return RoutePaths.loginPhone;
      }

      if (authSession.needSelectRole) {
        if (isSelectRoleRoute) {
          return null;
        }
        AppLogger.instance.warn(
          'ROUTE',
          '角色未选择，跳转到角色选择页',
          context: <String, Object?>{
            'from': location,
            'to': RoutePaths.selectRole,
          },
        );
        return RoutePaths.selectRole;
      }

      if (location == RoutePaths.root || isAuthRoute) {
        AppLogger.instance.info(
          'ROUTE',
          '登录态已就绪，跳转到首页',
          context: <String, Object?>{'from': location, 'to': RoutePaths.home},
        );
        return RoutePaths.home;
      }

      return null;
    },
    // initialLocation: RoutePaths.home,
    // initialLocation: RoutePaths.myOrders,
    // initialLocation: RoutePaths.loginPhone,
    // initialLocation: RoutePaths.qualificationCertification,
    // initialLocation: RoutePaths.selectRole,
    // initialLocation: RoutePaths.orderDetail,
    // initialLocation: RoutePaths.serviceDetail,
    routes: <RouteBase>[
      GoRoute(
        path: RoutePaths.root,
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: RoutePaths.loginPhone,
        name: RoutePaths.loginPhoneName,
        builder: (context, state) => const LoginPhonePage(),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertification,
        builder: (context, state) => const QualificationCertificationPage(),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertificationStepTwo,
        builder: (context, state) =>
            const QualificationCertificationStepTwoPage(),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertificationStepThree,
        builder: (context, state) =>
            const QualificationCertificationStepThreePage(),
      ),
      GoRoute(
        path: RoutePaths.selectRole,
        name: RoutePaths.selectRoleName,
        builder: (context, state) => const SelectRolePage(),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        builder: (context, state) =>
            JobDetailPage(args: state.extra as JobDetailPageArgs?),
      ),
      GoRoute(
        path: RoutePaths.postJob,
        name: RoutePaths.postJob,
        builder: (context, state) => const PostJobPage(),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        builder: (context, state) => const OrderDetailPage(),
      ),
      GoRoute(
        path: RoutePaths.orderReview,
        builder: (context, state) => const OrderReviewPage(),
      ),
      GoRoute(
        path: RoutePaths.serviceDetail,
        builder: (context, state) =>
            ServiceDetailPage(args: state.extra as ServiceDetailPageArgs?),
      ),
      GoRoute(
        path: RoutePaths.editVisaPackage,
        builder: (context, state) => const EditVisaPackagePage(),
      ),
      GoRoute(
        path: RoutePaths.serviceDetailReport,
        builder: (context, state) => const ServiceDetailReportPage(),
      ),
      GoRoute(
        path: RoutePaths.appResult,
        builder: (context, state) => AppResultPage(
          args:
              state.extra as AppResultPageArgs? ??
              const AppResultPageArgs.paymentSuccess(),
        ),
      ),
      GoRoute(
        path: RoutePaths.myInfo,
        builder: (context, state) => const MyInfoPage(),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.myOrders,
        builder: (context, state) => const MyOrdersPage(),
      ),
      GoRoute(
        path: RoutePaths.myFavorites,
        builder: (context, state) => const MyFavoritesPage(),
      ),
      GoRoute(
        path: RoutePaths.myResume,
        builder: (context, state) => const MyResumePage(),
      ),
      GoRoute(
        path: RoutePaths.myResumePreview,
        builder: (context, state) =>
            MyResumePreviewPage(args: state.extra as ResumePreviewArgs?),
      ),
      GoRoute(
        path: RoutePaths.myApplications,
        builder: (context, state) => const MyApplicationsPage(),
      ),
      GoRoute(
        path: RoutePaths.companyApplications,
        builder: (context, state) => const CompanyApplicationManagementPage(),
      ),
      GoRoute(
        path: RoutePaths.myResumeEditor,
        builder: (context, state) {
          final ResumeEditorArgs? args = state.extra as ResumeEditorArgs?;
          return MyResumeEditorPage(
            args: args ?? const ResumeEditorArgs.create(),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.addWorkExperience,
        builder: (context, state) => AddWorkExperiencePage(
          args: state.extra as AddWorkExperiencePageArgs? ??
              const AddWorkExperiencePageArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.addEducationExperience,
        builder: (context, state) => AddEducationExperiencePage(
          args: state.extra as AddEducationExperiencePageArgs? ??
              const AddEducationExperiencePageArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.addEducationSchool,
        builder: (context, state) =>
            AddEducationSchoolPage(initialSchool: state.extra as String?),
      ),
      GoRoute(
        path: RoutePaths.addSkillCertificate,
        builder: (context, state) => AddSkillCertificatePage(
          args: state.extra as AddSkillCertificatePageArgs? ??
              const AddSkillCertificatePageArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.selfEvaluation,
        builder: (context, state) =>
            SelfEvaluationPage(initialValue: state.extra as String? ?? ''),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShellPage(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.home,
                name: RoutePaths.homeName,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.visa,
                builder: (context, state) => const VisaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.jobs,
                builder: (context, state) => const JobsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.ai,
                builder: (context, state) => const AiAssistantPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: RoutePaths.me,
                builder: (context, state) => const MePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // go_router 刚创建时，首轮路由匹配可能尚未完成，此时直接读取 state 会抛错。
  String previousLocation = _readCurrentLocation(
    router,
    fallbackLocation: RoutePaths.loginPhone,
  );
  AppLogger.instance.info(
    'ROUTE',
    '路由器初始化完成',
    context: <String, Object?>{'location': previousLocation},
  );

  /// 监听 go_router 当前地址变化，记录真实跳转结果。
  void handleRouteChanged() {
    final currentLocation = _readCurrentLocation(
      router,
      fallbackLocation: previousLocation,
    );
    if (currentLocation == previousLocation) {
      return;
    }
    AppLogger.instance.info(
      'ROUTE',
      '路由已切换',
      context: <String, Object?>{
        'from': previousLocation,
        'to': currentLocation,
      },
    );
    previousLocation = currentLocation;
  }

  router.routerDelegate.addListener(handleRouteChanged);
  ref.onDispose(() {
    router.routerDelegate.removeListener(handleRouteChanged);
  });

  return router;
});

/// 安全读取当前路由地址，避免 go_router 在首轮匹配前访问 `state` 抛出异常。
String _readCurrentLocation(
  GoRouter router, {
  required String fallbackLocation,
}) {
  try {
    return router.state.uri.toString();
  } on StateError {
    // 关键兜底：初始化阶段尚未产生 match 时，回退到已知地址。
    return fallbackLocation;
  }
}
