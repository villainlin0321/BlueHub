import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_session_provider.dart';
import '../../features/auth/application/auth_session_state.dart';
import '../../features/auth/presentation/login_phone_page.dart';
import '../../features/auth/presentation/qualification_certification_flow.dart';
import '../../features/auth/presentation/qualification_certification_page.dart';
import '../../features/auth/presentation/qualification_certification_step_three_page.dart';
import '../../features/auth/presentation/qualification_certification_step_two_page.dart';
import '../../features/auth/select_role/presentation/select_role_page.dart';
import '../../features/ai/presentation/ai_assistant_page.dart';
import '../../features/complaint/presentation/complaint_detail_page.dart';
import '../../features/complaint/presentation/my_complaints_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jobs/presentation/company_application_management_page.dart';
import '../../features/jobs/presentation/job_detail_page.dart';
import '../../features/jobs/presentation/job_search_page.dart';
import '../../features/jobs/presentation/jobs_page.dart';
import '../../features/jobs/presentation/post_job_page.dart';
import '../../features/jobs/presentation/role_pages/company_jobs_page.dart';
import '../../features/jobs/presentation/service_provider_talent_center_page.dart';
import '../../features/me/presentation/me_page.dart';
import '../../features/me/presentation/add_education_experience_page.dart';
import '../../features/me/presentation/add_education_school_page.dart';
import '../../features/me/presentation/add_work_experience_page.dart';
import '../../features/me/presentation/add_skill_certificate_page.dart';
import '../../features/me/presentation/about_app_page.dart';
import '../../features/me/presentation/my_applications_page.dart';
import '../../features/me/presentation/company_my_info_page.dart';
import '../../features/me/presentation/blacklist_page.dart';
import '../../features/me/presentation/finance_bank_cards_page.dart';
import '../../features/me/presentation/finance_settlement_page.dart';
import '../../features/me/presentation/finance_transactions_page.dart';
import '../../features/me/presentation/finance_withdrawals_page.dart';
import '../../features/me/presentation/my_favorites_page.dart';
import '../../features/me/presentation/my_info_page.dart';
import '../../features/me/presentation/my_info_contact_edit_page.dart';
import '../../features/me/presentation/job_seeker_real_name_verification_page.dart';
import '../../features/me/presentation/my_resume_editor_page.dart';
import '../../features/me/presentation/my_resume_page.dart';
import '../../features/me/presentation/my_resume_preview_page.dart';
import '../../features/me/presentation/service_provider_my_info_page.dart';
import '../../features/me/presentation/settings_page.dart';
import '../../features/message/application/chat/chat_page_args.dart';
import '../../features/message/presentation/chat_page.dart';
import '../../features/message/presentation/message_center_page.dart';
import '../../features/order/presentation/order_detail_page.dart';
import '../../features/order/presentation/order_management_page.dart';
import '../../features/order/presentation/order_review_page.dart';
import '../../features/me/presentation/self_evaluation_page.dart';
import '../../features/service_detail/presentation/app_result_page.dart';
import '../../features/service_detail/presentation/service_detail_page.dart';
import '../../features/service_detail/presentation/visa_package_preview_page.dart';
import '../../features/service_detail/presentation/service_detail_report_page.dart';
import '../../features/me/presentation/my_orders_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/visa/presentation/company_visa_service_page.dart';
import '../../features/visa/presentation/edit_visa_package_page.dart';
import '../../features/visa/presentation/visa_provider_search_page.dart';
import '../../features/visa/presentation/visa_page.dart';
import '../../shared/logging/app_log_event.dart';
import '../../shared/logging/app_log_facade.dart';
import '../../shared/logging/app_route_tracker.dart';
import '../../shared/presentation/attachment_preview_page.dart';
import 'route_paths.dart';

/// 提供全局 `GoRouter` 实例，并在关键路由变化时输出日志。
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  final routeTracker = AppRouteTracker.instance;
  final routeLogCoordinator = RouteLogCoordinator();
  ref.onDispose(refreshNotifier.dispose);
  ref.listen(authSessionProvider, (_, __) {
    refreshNotifier.refresh();
  });

  final router = GoRouter(
    initialLocation: RoutePaths.loginPhone,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authSession = ref.read(authSessionProvider);
      final location = state.matchedLocation;
      final pendingRedirect = _extractSafeRedirectTarget(state.uri);
      final isLoginRoute = location == RoutePaths.loginPhone;
      final isSelectRoleRoute = location == RoutePaths.selectRole;
      final isAuthRoute = isLoginRoute || isSelectRoleRoute;

      if (authSession.isHydrating) {
        RouteLog.log(
          event: 'ROUTE_GUARD_SKIPPED',
          message: '会话恢复中，暂不拦截路由',
          level: AppLogLevel.debug,
          result: AppLogResult.skip,
          context: <String, Object?>{'location': location},
        );
        return null;
      }

      if (!authSession.isAuthenticated) {
        if (isLoginRoute) {
          return null;
        }
        final redirectTarget =
            pendingRedirect ?? _buildRedirectTargetFromStateUri(state.uri);
        final authEntryLocation = _buildAuthEntryLocation(
          RoutePaths.loginPhone,
          redirectTarget,
        );
        RouteLog.redirectApplied(
          from: location,
          to: authEntryLocation,
          reason: 'unauthenticated',
          context: _buildRedirectLogContext(
            redirectTarget: redirectTarget,
            authSession: authSession,
          ),
        );
        return authEntryLocation;
      }

      if (authSession.needSelectRole) {
        if (isSelectRoleRoute) {
          return null;
        }
        final redirectTarget =
            pendingRedirect ?? _buildRedirectTargetFromStateUri(state.uri);
        final selectRoleLocation = _buildAuthEntryLocation(
          RoutePaths.selectRole,
          redirectTarget,
        );
        RouteLog.redirectApplied(
          from: location,
          to: selectRoleLocation,
          reason: 'role_not_selected',
          context: _buildRedirectLogContext(
            redirectTarget: redirectTarget,
            authSession: authSession,
          ),
        );
        return selectRoleLocation;
      }

      if (location == RoutePaths.root || isAuthRoute) {
        final target = pendingRedirect;
        RouteLog.redirectApplied(
          from: location,
          to: target ?? RoutePaths.home,
          reason: target == null
              ? 'auth_ready_default_home'
              : 'auth_ready_resume_target',
          level: AppLogLevel.info,
          context: _buildRedirectLogContext(
            redirectTarget: target,
            authSession: authSession,
          ),
        );
        return target ?? RoutePaths.home;
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
        builder: (context, state) => QualificationCertificationPage(
          args:
              state.extra as QualificationCertificationPageArgs? ??
              QualificationCertificationPageArgs(
                role: QualificationCertificationRole.serviceProvider,
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertificationStepTwo,
        builder: (context, state) => QualificationCertificationStepTwoPage(
          args:
              state.extra as QualificationCertificationPageArgs? ??
              QualificationCertificationPageArgs(
                role: QualificationCertificationRole.serviceProvider,
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.qualificationCertificationStepThree,
        builder: (context, state) => QualificationCertificationStepThreePage(
          args:
              state.extra as QualificationCertificationPageArgs? ??
              QualificationCertificationPageArgs(
                role: QualificationCertificationRole.serviceProvider,
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.selectRole,
        name: RoutePaths.selectRoleName,
        builder: (context, state) => const SelectRolePage(),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        builder: (context, state) => JobDetailPage(
          args:
              state.extra as JobDetailPageArgs? ??
              _buildJobDetailArgsFromUri(state.uri),
        ),
      ),
      GoRoute(
        path: RoutePaths.postJob,
        name: RoutePaths.postJob,
        builder: (context, state) => PostJobPage(
          args:
              state.extra as PostJobPageArgs? ?? const PostJobPageArgs.create(),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderManagement,
        builder: (context, state) => const OrderManagementPage(),
      ),
      GoRoute(
        path: RoutePaths.orderDetail,
        builder: (context, state) => OrderDetailPage(
          args:
              state.extra as OrderDetailPageArgs? ??
              _buildOrderDetailArgsFromUri(state.uri) ??
              const OrderDetailPageArgs(orderId: 0),
        ),
      ),
      GoRoute(
        path: RoutePaths.orderReview,
        builder: (context, state) => OrderReviewPage(
          args:
              state.extra as OrderReviewPageArgs? ??
              const OrderReviewPageArgs(
                orderId: 0,
                providerId: 0,
                title: '',
                price: '',
                providerName: '',
                packageType: '',
                orderNo: '',
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.financeSettlement,
        builder: (context, state) => const FinanceSettlementPage(),
      ),
      GoRoute(
        path: RoutePaths.financeTransactions,
        builder: (context, state) => const FinanceTransactionsPage(),
      ),
      GoRoute(
        path: RoutePaths.financeWithdrawals,
        builder: (context, state) => const FinanceWithdrawalsPage(),
      ),
      GoRoute(
        path: RoutePaths.financeBankCards,
        builder: (context, state) => const FinanceBankCardsPage(),
      ),
      GoRoute(
        path: RoutePaths.serviceDetail,
        builder: (context, state) => ServiceDetailPage(
          args:
              state.extra as ServiceDetailPageArgs? ??
              _buildServiceDetailArgsFromUri(state.uri),
        ),
      ),
      GoRoute(
        path: RoutePaths.serviceDetailPreview,
        builder: (context, state) => VisaPackagePreviewPage(
          args:
              state.extra as VisaPackagePreviewPageArgs? ??
              VisaPackagePreviewPageArgs(
                packageId:
                    int.tryParse(
                      state.uri.queryParameters['packageId'] ?? '',
                    ) ??
                    0,
                providerId: int.tryParse(
                  state.uri.queryParameters['providerId'] ?? '',
                ),
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.editVisaPackage,
        builder: (context, state) => EditVisaPackagePage(
          packageId: int.tryParse(state.uri.queryParameters['packageId'] ?? ''),
        ),
      ),
      GoRoute(
        path: RoutePaths.serviceDetailReport,
        builder: (context, state) => ServiceDetailReportPage(
          args:
              state.extra as ServiceDetailReportPageArgs? ??
              const ServiceDetailReportPageArgs(
                targetType: '',
                targetId: 0,
                targetName: '',
              ),
        ),
      ),
      GoRoute(
        path: RoutePaths.myComplaints,
        builder: (context, state) => const MyComplaintsPage(),
      ),
      GoRoute(
        path: RoutePaths.complaintDetail,
        builder: (context, state) => ComplaintDetailPage(
          args:
              state.extra as ComplaintDetailPageArgs? ??
              const ComplaintDetailPageArgs(complaintId: 0),
        ),
      ),
      GoRoute(
        path: RoutePaths.appResult,
        builder: (context, state) => AppResultPage(
          args:
              state.extra as AppResultPageArgs? ??
              AppResultPageArgs.paymentSuccess(),
        ),
      ),
      GoRoute(
        path: RoutePaths.jobSearch,
        builder: (context, state) => const JobSearchPage(),
      ),
      GoRoute(
        path: RoutePaths.talentSearch,
        builder: (context, state) => TalentSearchPage(
          args:
              state.extra as TalentSearchPageArgs? ??
              const TalentSearchPageArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.myInfo,
        builder: (context, state) => const MyInfoPage(),
      ),
      GoRoute(
        path: RoutePaths.myInfoContactEdit,
        builder: (context, state) => MyInfoContactEditPage(
          args:
              state.extra as MyInfoContactEditPageArgs? ??
              const MyInfoContactEditPageArgs.email(),
        ),
      ),
      GoRoute(
        path: RoutePaths.jobSeekerRealNameVerification,
        builder: (context, state) => const JobSeekerRealNameVerificationPage(),
      ),
      GoRoute(
        path: RoutePaths.serviceProviderMyInfo,
        builder: (context, state) => ServiceProviderMyInfoPage(
          args:
              state.extra as ServiceProviderMyInfoPageArgs? ??
              const ServiceProviderMyInfoPageArgs.my(),
        ),
      ),
      GoRoute(
        path: RoutePaths.companyMyInfo,
        builder: (context, state) => CompanyMyInfoPage(
          args:
              state.extra as CompanyMyInfoPageArgs? ??
              const CompanyMyInfoPageArgs.my(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: RoutePaths.aboutApp,
        builder: (context, state) => const AboutAppPage(),
      ),
      GoRoute(
        path: RoutePaths.blacklist,
        builder: (context, state) => const BlacklistPage(),
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
        path: RoutePaths.messageCenter,
        builder: (context, state) => const MessageCenterPage(),
      ),
      GoRoute(
        path: RoutePaths.chat,
        builder: (context, state) {
          final ChatPageArgs? args = state.extra as ChatPageArgs?;
          return ChatPage(
            args:
                args ??
                ChatPageArgs(
                  targetUserId: 0,
                  targetUserRole: '',
                  nickname: '消息.聊天'.tr(),
                  avatarUrl: '',
                ),
          );
        },
      ),
      GoRoute(
        path: RoutePaths.myResume,
        builder: (context, state) => const MyResumePage(),
      ),
      GoRoute(
        path: RoutePaths.resumePreview,
        builder: (context, state) {
          final Object? extra = state.extra;
          if (extra is ResumePreviewArgs) {
            return MyResumePreviewPage(args: extra);
          }
          if (extra is int) {
            return MyResumePreviewPage(userId: extra, title: '我的.简历详情标题'.tr());
          }
          return const MyResumePreviewPage();
        },
      ),
      GoRoute(
        path: RoutePaths.attachmentPreview,
        builder: (context, state) {
          final AttachmentPreviewArgs? args =
              state.extra as AttachmentPreviewArgs?;
          return AttachmentPreviewPage(
            args:
                args ??
                const AttachmentPreviewArgs(
                  path: '',
                  title: '',
                  isImage: false,
                  isPdf: false,
                ),
          );
        },
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
        path: RoutePaths.companyVisaService,
        builder: (context, state) => const CompanyVisaServicePage(),
      ),
      GoRoute(
        path: RoutePaths.visaProviderSearch,
        builder: (context, state) => const VisaProviderSearchPage(),
      ),
      GoRoute(
        path: RoutePaths.serviceProviderTalentCenter,
        builder: (context, state) => const ServiceProviderTalentCenterPage(),
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
          args:
              state.extra as AddWorkExperiencePageArgs? ??
              const AddWorkExperiencePageArgs(),
        ),
      ),
      GoRoute(
        path: RoutePaths.addEducationExperience,
        builder: (context, state) => AddEducationExperiencePage(
          args:
              state.extra as AddEducationExperiencePageArgs? ??
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
          args:
              state.extra as AddSkillCertificatePageArgs? ??
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

  _emitRouteTransitions(
    coordinator: routeLogCoordinator,
    routeTracker: routeTracker,
    currentLocation: _tryReadCurrentLocation(router),
    source: 'router_init',
  );

  /// 监听 go_router 当前地址变化，记录真实跳转结果。
  void handleRouteChanged() {
    _emitRouteTransitions(
      coordinator: routeLogCoordinator,
      routeTracker: routeTracker,
      currentLocation: _tryReadCurrentLocation(router),
      source: 'router_delegate',
    );
  }

  router.routerDelegate.addListener(handleRouteChanged);
  ref.onDispose(() {
    router.routerDelegate.removeListener(handleRouteChanged);
  });

  return router;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

/// 尝试读取当前真实路由地址；若首轮匹配尚未完成，则返回空并等待后续监听补齐。
String? _tryReadCurrentLocation(GoRouter router) {
  try {
    return router.state.uri.toString();
  } on StateError {
    // 关键兜底：初始化阶段尚未拿到真实路由时，绝不伪造 `/login` 之类的首屏日志。
    return null;
  }
}

/// 将一次路由同步结果转成结构化日志，并同步更新路由追踪器。
void _emitRouteTransitions({
  required RouteLogCoordinator coordinator,
  required AppRouteTracker routeTracker,
  required String? currentLocation,
  required String source,
}) {
  final transitions = coordinator.sync(currentLocation: currentLocation);
  for (final transition in transitions) {
    switch (transition.type) {
      case RouteLogTransitionType.exit:
        RouteLog.exit(
          route: transition.route,
          to: transition.to,
          context: <String, Object?>{'source': source},
        );
        break;
      case RouteLogTransitionType.enter:
        routeTracker.track(transition.route);
        RouteLog.enter(
          route: transition.route,
          from: transition.from,
          context: <String, Object?>{
            'source': source,
            if (routeTracker.previousRoute != null)
              'trackerPreviousRoute': routeTracker.previousRoute,
          },
        );
        break;
    }
  }
}

/// 路由日志协调器：只在拿到真实路由后产生日志，并统一推导进出场顺序。
class RouteLogCoordinator {
  String? _currentLocation;

  /// 根据最新真实路由生成需要输出的过渡事件；初始未解析阶段不会产生日志。
  List<RouteLogTransition> sync({required String? currentLocation}) {
    final normalizedLocation = _normalizeLocation(currentLocation);
    if (normalizedLocation == null) {
      return const <RouteLogTransition>[];
    }
    if (_currentLocation == null) {
      _currentLocation = normalizedLocation;
      return <RouteLogTransition>[
        RouteLogTransition.enter(route: normalizedLocation),
      ];
    }
    if (_currentLocation == normalizedLocation) {
      return const <RouteLogTransition>[];
    }

    final previousLocation = _currentLocation!;
    _currentLocation = normalizedLocation;
    return <RouteLogTransition>[
      RouteLogTransition.exit(route: previousLocation, to: normalizedLocation),
      RouteLogTransition.enter(
        route: normalizedLocation,
        from: previousLocation,
      ),
    ];
  }

  /// 统一清洗路由字符串，避免空白值污染协调状态。
  String? _normalizeLocation(String? currentLocation) {
    final normalizedLocation = currentLocation?.trim();
    if (normalizedLocation == null || normalizedLocation.isEmpty) {
      return null;
    }
    return normalizedLocation;
  }
}

/// 路由过渡类型：用于区分页面退出和进入事件。
enum RouteLogTransitionType { exit, enter }

/// 单次路由过渡事件，供协调器与日志输出流程之间传递。
class RouteLogTransition {
  const RouteLogTransition._({
    required this.type,
    required this.route,
    this.from,
    this.to,
  });

  final RouteLogTransitionType type;
  final String route;
  final String? from;
  final String? to;

  /// 构建页面进入事件。
  factory RouteLogTransition.enter({required String route, String? from}) {
    return RouteLogTransition._(
      type: RouteLogTransitionType.enter,
      route: route,
      from: from,
    );
  }

  /// 构建页面退出事件。
  factory RouteLogTransition.exit({required String route, String? to}) {
    return RouteLogTransition._(
      type: RouteLogTransitionType.exit,
      route: route,
      to: to,
    );
  }
}

/// 生成登录/选角色入口地址，并在需要时透传原始目标路由，避免登录后丢失 Universal Link。
String _buildAuthEntryLocation(String basePath, String? redirectTarget) {
  if (redirectTarget == null || redirectTarget.isEmpty) {
    return basePath;
  }
  return Uri(
    path: basePath,
    queryParameters: <String, String>{'redirect': redirectTarget},
  ).toString();
}

/// 从当前地址提取可恢复的站内目标路由，只允许应用内部相对路径，避免外部跳转注入。
String? _extractSafeRedirectTarget(Uri uri) {
  final rawTarget = uri.queryParameters['redirect']?.trim();
  if (rawTarget == null || rawTarget.isEmpty) {
    return null;
  }
  final parsedTarget = Uri.tryParse(rawTarget);
  if (parsedTarget == null) {
    return null;
  }
  if (parsedTarget.hasScheme || parsedTarget.host.isNotEmpty) {
    return null;
  }
  if (!parsedTarget.path.startsWith('/')) {
    return null;
  }
  if (_isAuthPath(parsedTarget.path) || parsedTarget.path == RoutePaths.root) {
    return null;
  }
  return parsedTarget.toString();
}

/// 从当前访问地址反推“登录后应恢复到哪里”，只保留真正的业务页地址。
String? _buildRedirectTargetFromStateUri(Uri uri) {
  if (_isAuthPath(uri.path) || uri.path == RoutePaths.root) {
    return null;
  }
  return uri.toString();
}

/// 判断当前路径是否属于鉴权入口页，避免在登录页和选角色页之间产生循环跳转。
bool _isAuthPath(String path) {
  return path == RoutePaths.loginPhone || path == RoutePaths.selectRole;
}

/// 统一补齐重定向日志上下文，明确当前会话状态和目标恢复地址。
Map<String, Object?> _buildRedirectLogContext({
  required AuthSessionState authSession,
  String? redirectTarget,
}) {
  return <String, Object?>{
    'isAuthenticated': authSession.isAuthenticated,
    'isHydrating': authSession.isHydrating,
    'needSelectRole': authSession.needSelectRole,
    if (authSession.user != null) 'userId': authSession.user!.userId,
    if (redirectTarget != null) 'redirectTarget': redirectTarget,
  };
}

/// 解析岗位详情链接参数，支持 Universal Link 直接使用 `jobId` 查询参数打开页面。
JobDetailPageArgs? _buildJobDetailArgsFromUri(Uri uri) {
  final jobId = _readPositiveIntQueryParameter(uri, 'jobId');
  if (jobId == null) {
    return null;
  }
  return JobDetailPageArgs(jobId: jobId);
}

/// 解析订单详情链接参数，支持通过 `orderId` 查询参数直达订单页面。
OrderDetailPageArgs? _buildOrderDetailArgsFromUri(Uri uri) {
  final orderId = _readPositiveIntQueryParameter(uri, 'orderId');
  if (orderId == null) {
    return null;
  }
  return OrderDetailPageArgs(orderId: orderId);
}

/// 解析签证服务详情链接参数，兼容 `packageId/providerId/isCollected` 的站内分享形式。
ServiceDetailPageArgs? _buildServiceDetailArgsFromUri(Uri uri) {
  final packageId = _readPositiveIntQueryParameter(uri, 'packageId');
  if (packageId == null) {
    return null;
  }
  return ServiceDetailPageArgs(
    packageId: packageId,
    providerId: _readPositiveIntQueryParameter(uri, 'providerId'),
    initialIsCollected: _readBoolQueryParameter(uri, 'isCollected') ?? false,
  );
}

/// 统一读取正整数查询参数，非法值直接返回空，避免路由层因脏参数抛异常。
int? _readPositiveIntQueryParameter(Uri uri, String key) {
  final rawValue = uri.queryParameters[key];
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }
  final value = int.tryParse(rawValue);
  if (value == null || value <= 0) {
    return null;
  }
  return value;
}

/// 统一解析布尔查询参数，兼容常见的 `true/false/1/0/yes/no` 写法。
bool? _readBoolQueryParameter(Uri uri, String key) {
  final rawValue = uri.queryParameters[key]?.trim().toLowerCase();
  switch (rawValue) {
    case 'true':
    case '1':
    case 'yes':
      return true;
    case 'false':
    case '0':
    case 'no':
      return false;
    default:
      return null;
  }
}
