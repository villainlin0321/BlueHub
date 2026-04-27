import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'my_applications_models.dart';

final myApplicationsProvider =
    Provider<Map<MyApplicationTabType, List<MyApplicationItem>>>((ref) {
      // 先以本地演示数据承载 Figma 布局，后续接接口时只需替换这里的上游来源。
      const allItems = <MyApplicationItem>[
        MyApplicationItem(
          status: MyApplicationStatus.interview,
          updatedText: '10分钟前更新',
          title: '中餐厨师',
          salary: '€2,500',
          companyName: '柏林老四川餐厅',
          locationText: '德国·柏林',
        ),
        MyApplicationItem(
          status: MyApplicationStatus.viewed,
          updatedText: '10分钟前更新',
          title: '建筑工',
          salary: '€2,500',
          companyName: '柏林老四川餐厅',
          locationText: '德国·柏林',
        ),
        MyApplicationItem(
          status: MyApplicationStatus.applied,
          updatedText: '2026-03-23',
          title: '养老院护理员',
          salary: '€2,500',
          companyName: '柏林老四川餐厅',
          locationText: '德国·柏林',
        ),
        MyApplicationItem(
          status: MyApplicationStatus.applied,
          updatedText: '昨天 12:00:12',
          title: '中餐帮厨',
          salary: '€2,500',
          companyName: '柏林老四川餐厅',
          locationText: '德国·柏林',
        ),
      ];

      return <MyApplicationTabType, List<MyApplicationItem>>{
        MyApplicationTabType.all: allItems,
        MyApplicationTabType.applied: allItems
            .where((item) => item.status == MyApplicationStatus.applied)
            .toList(growable: false),
        MyApplicationTabType.viewed: allItems
            .where((item) => item.status == MyApplicationStatus.viewed)
            .toList(growable: false),
        MyApplicationTabType.interview: allItems
            .where((item) => item.status == MyApplicationStatus.interview)
            .toList(growable: false),
      };
    });
