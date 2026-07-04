import '../shared/patrol_test_types.dart';

/// 汇总服务商首页的可达性验收点，供 Patrol 测试与报告统一复用。
const List<PatrolCaseDefinition> serviceProviderHomeCases =
    <PatrolCaseDefinition>[
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'home',
        feature: 'home.quick_action.publish_package',
        description: '发布套餐快捷入口',
        precondition: '已进入服务商首页',
        expected: '进入编辑套餐页',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'home',
        feature: 'home.quick_action.order_management',
        description: '订单处理快捷入口',
        precondition: '已进入服务商首页',
        expected: '进入订单管理页',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'home',
        feature: 'home.quick_action.talent_center',
        description: '人才中心快捷入口',
        precondition: '已进入服务商首页',
        expected: '进入人才中心页',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'home',
        feature: 'home.quick_action.finance_settlement',
        description: '财务结算快捷入口',
        precondition: '已进入服务商首页',
        expected: '进入财务结算页',
      ),
    ];

/// 汇总服务商“我的”页的验收点，资质管理允许在数据不满足时记为阻塞。
const List<PatrolCaseDefinition> serviceProviderMeCases =
    <PatrolCaseDefinition>[
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'me',
        feature: 'me.menu.qualification_management',
        description: '资质管理',
        precondition: '已进入服务商我的页',
        expected: '进入资质认证流程，或因资料缺失记为阻塞',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'me',
        feature: 'me.menu.order_management',
        description: '订单管理',
        precondition: '已进入服务商我的页',
        expected: '进入订单管理页',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'me',
        feature: 'me.menu.finance_settlement',
        description: '财务结算',
        precondition: '已进入服务商我的页',
        expected: '进入财务结算页',
      ),
      PatrolCaseDefinition(
        module: 'service_provider',
        page: 'me',
        feature: 'me.menu.settings',
        description: '设置',
        precondition: '已进入服务商我的页',
        expected: '进入设置页',
      ),
    ];
