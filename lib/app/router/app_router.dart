import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_phone_page.dart';
import '../../features/auth/presentation/qualification_certification_page.dart';
import '../../features/auth/presentation/qualification_certification_step_three_page.dart';
import '../../features/auth/presentation/qualification_certification_step_two_page.dart';
import '../../features/auth/select_role/presentation/select_role_page.dart';
import '../../features/ai/presentation/ai_assistant_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jobs/presentation/job_detail_page.dart';
import '../../features/jobs/presentation/jobs_page.dart';
import '../../features/me/presentation/me_page.dart';
import '../../features/me/presentation/add_education_experience_page.dart';
import '../../features/me/presentation/add_education_school_page.dart';
import '../../features/me/presentation/add_work_experience_page.dart';
import '../../features/me/presentation/add_skill_certificate_page.dart';
import '../../features/me/presentation/my_applications_page.dart';
import '../../features/me/presentation/my_favorites_page.dart';
import '../../features/me/presentation/my_resume_editor_page.dart';
import '../../features/me/presentation/my_resume_page.dart';
import '../../features/me/presentation/my_resume_preview_page.dart';
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
import 'route_paths.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    // initialLocation: RoutePaths.myOrders,
    // initialLocation: RoutePaths.loginPhone,
    // initialLocation: RoutePaths.qualificationCertification,
    // initialLocation: RoutePaths.selectRole,
    // initialLocation: RoutePaths.orderDetail,
    // initialLocation: RoutePaths.serviceDetail,
    routes: <RouteBase>[
      GoRoute(path: RoutePaths.root, redirect: (_, __) => RoutePaths.home),
      GoRoute(
        path: RoutePaths.loginPhone,
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
        name: RoutePaths.selectRole,
        builder: (context, state) => const SelectRolePage(),
      ),
      GoRoute(
        path: RoutePaths.jobDetail,
        builder: (context, state) => const JobDetailPage(),
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
        builder: (context, state) => const ServiceDetailPage(),
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
            MyResumePreviewPage(draft: state.extra as ResumeDraft?),
      ),
      GoRoute(
        path: RoutePaths.myApplications,
        builder: (context, state) => const MyApplicationsPage(),
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
        builder: (context, state) => const AddWorkExperiencePage(),
      ),
      GoRoute(
        path: RoutePaths.addEducationExperience,
        builder: (context, state) => const AddEducationExperiencePage(),
      ),
      GoRoute(
        path: RoutePaths.addEducationSchool,
        builder: (context, state) =>
            AddEducationSchoolPage(initialSchool: state.extra as String?),
      ),
      GoRoute(
        path: RoutePaths.addSkillCertificate,
        builder: (context, state) => const AddSkillCertificatePage(),
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
});
