import 'package:patrol/patrol.dart';

import 'package:europepass/main.dart' as app;

/// 启动真实应用入口，并等待首帧稳定，保证 Patrol 与正式启动流程一致。
Future<void> bootstrapPatrolApp(PatrolIntegrationTester $) async {
  await app.main();
  await $.pumpAndSettle();
}
