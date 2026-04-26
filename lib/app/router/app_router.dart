import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_phone_page.dart';
import '../../features/auth/select_role/presentation/select_role_page.dart';
import '../../features/ai/presentation/ai_assistant_page.dart';
import '../../features/home/presentation/home_page.dart';
import '../../features/jobs/presentation/jobs_page.dart';
import '../../features/me/presentation/me_page.dart';
import '../../features/order/presentation/order_detail_page.dart';
import '../../features/order/presentation/order_review_page.dart';
import '../../features/service_detail/presentation/service_detail_page.dart';
import '../../features/me/presentation/my_orders_page.dart';
import '../../features/shell/presentation/main_shell_page.dart';
import '../../features/visa/presentation/visa_page.dart';
import '../app.dart';
import 'route_paths.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    // initialLocation: RoutePaths.home,
    // initialLocation: RoutePaths.loginPhone,
    // initialLocation: RoutePaths.selectRole,
    // initialLocation: RoutePaths.orderDetail,
    // initialLocation: RoutePaths.serviceDetail,
    initialLocation: RoutePaths.myOrders,
    routes: <RouteBase>[
      GoRoute(path: RoutePaths.root, redirect: (_, __) => RoutePaths.home),
      GoRoute(
        path: RoutePaths.loginPhone,
        builder: (context, state) => const LoginPhonePage(),
      ),
      GoRoute(
        path: RoutePaths.selectRole,
        builder: (context, state) => const SelectRolePage(),
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
        path: RoutePaths.myOrders,
        builder: (context, state) => const MyOrdersPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShellPage(
          title: ref.read(appTitleProvider),
          navigationShell: navigationShell,
        ),
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
