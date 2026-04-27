import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/route_paths.dart';
import '../data/my_applications_models.dart';
import '../data/my_applications_providers.dart';
import 'widgets/my_application_card.dart';

class MyApplicationsPage extends ConsumerWidget {
  const MyApplicationsPage({super.key});

  static const List<MyApplicationTabType> _tabs = MyApplicationTabType.values;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsByTab = ref.watch(myApplicationsProvider);

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          scrolledUnderElevation: 0,
          leadingWidth: 44,
          leading: IconButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
                return;
              }
              context.go(RoutePaths.me);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF262626),
            ),
          ),
          title: const Text(
            '我的应聘',
            style: TextStyle(
              color: Color(0xE6262626),
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            Container(
              height: 44,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0x297E868E), width: 0.5),
                ),
              ),
              child: TabBar(
                tabs: _tabs
                    .map((tab) => Tab(height: 44, text: tab.label))
                    .toList(growable: false),
                labelColor: const Color(0xFF096DD9),
                unselectedLabelColor: const Color(0xFF262626),
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 22 / 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  height: 22 / 14,
                ),
                indicatorSize: TabBarIndicatorSize.label,
                indicatorWeight: 2,
                indicatorColor: const Color(0xFF096DD9),
                dividerColor: Colors.transparent,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: _tabs.map((tab) {
                  final items = itemsByTab[tab] ?? const <MyApplicationItem>[];
                  return ListView.builder(
                    key: PageStorageKey<String>('my-applications-${tab.name}'),
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: items.length + 1,
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Center(
                            child: Text(
                              '暂无更多记录',
                              style: const TextStyle(
                                color: Color(0xFFBFBFBF),
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                height: 18 / 12,
                              ),
                            ),
                          ),
                        );
                      }

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index == items.length - 1 ? 0 : 12,
                        ),
                        child: MyApplicationCard(
                          item: items[index],
                          onActionTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${items[index].actionLabel}（占位）'),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                }).toList(growable: false),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
