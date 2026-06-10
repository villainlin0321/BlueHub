import 'package:bluehub_app/shared/network/models/dictionary_models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_toast.dart';

import '../data/dictionary_providers.dart';
import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class AddEducationSchoolPage extends ConsumerStatefulWidget {
  const AddEducationSchoolPage({super.key, this.initialSchool});

  final String? initialSchool;

  @override
  ConsumerState<AddEducationSchoolPage> createState() =>
      _AddEducationSchoolPageState();
}

class _AddEducationSchoolPageState
    extends ConsumerState<AddEducationSchoolPage> {
  late final TextEditingController _searchController = TextEditingController(
    text: _initialKeyword(widget.initialSchool),
  )..addListener(_handleSearchChanged);

  String? _selectedSchool;

  static String _initialKeyword(String? initialSchool) {
    if ((initialSchool ?? '').trim().isEmpty) {
      return '';
    }
    final String normalized = initialSchool!.trim();
    return normalized.length <= 2 ? normalized : normalized.substring(0, 2);
  }

  @override
  void initState() {
    super.initState();
    _selectedSchool = widget.initialSchool;
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_handleSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    setState(() {
      if (_selectedSchool != null && !_selectedSchool!.contains(_keyword)) {
        _selectedSchool = null;
      }
    });
  }

  String get _keyword => _searchController.text.trim();

  SchoolSearchQuery get _query => SchoolSearchQuery(
    keyword: _keyword.isEmpty ? null : _keyword,
    page: 1,
    pageSize: 20,
  );

  void _handleConfirm(List<SchoolVO> schools) {
    final List<String> schoolNames = schools
        .map(_resolveSchoolName)
        .where((String name) => name.isNotEmpty)
        .toList(growable: false);
    final String? result =
        _selectedSchool ??
        (schoolNames.contains(_keyword) ? _keyword : null) ??
        (schoolNames.length == 1 ? schoolNames.first : null);

    if (result == null) {
      AppToast.show('我的.请选择学校'.tr());
      return;
    }

    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final schoolsAsync = ref.watch(schoolSearchProvider(_query));
    final List<SchoolVO> schools =
        schoolsAsync.asData?.value.list ?? <SchoolVO>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF171A1D),
          ),
        ),
        title: Text(
          '我的.学校'.tr(),
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => _handleConfirm(schools),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF262626),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Text(
              '通用.确定'.tr(),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 20 / 14,
              ),
            ),
          ),
        ],
      ),
      body: TapBlankToDismissKeyboard(
        child: SafeArea(
          top: false,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Container(
                  alignment: Alignment.center,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      cursorColor: const Color(0xFF096DD9),
                      style: const TextStyle(
                        color: Color(0xFF262626),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                      decoration: InputDecoration(
                        hintText: '我的.请输入学校名称'.tr(),
                        hintStyle: TextStyle(
                          color: Color(0xFFBFBFBF),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 20 / 14,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: schoolsAsync.when(
                  data: (pageResult) {
                    if (pageResult.list.isEmpty) {
                      return Center(
                        child: Text(
                          _keyword.isEmpty
                              ? '我的.暂无学校数据'.tr()
                              : '我的.未找到相关学校'.tr(),
                          style: const TextStyle(
                            color: Color(0xFF8C8C8C),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: pageResult.list.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 0.5,
                        thickness: 0.5,
                        indent: 16,
                        color: Color(0xFFF0F0F0),
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final SchoolVO school = pageResult.list[index];
                        final String schoolName = _resolveSchoolName(school);
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSchool = schoolName;
                              _searchController.value = TextEditingValue(
                                text: schoolName,
                                selection: TextSelection.collapsed(
                                  offset: schoolName.length,
                                ),
                              );
                            });
                          },
                          child: Container(
                            height: 52,
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            alignment: Alignment.centerLeft,
                            child: RichText(
                              text: _buildHighlightedText(schoolName, _keyword),
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (_, __) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '我的.学校加载失败'.tr(),
                          style: TextStyle(
                            color: Color(0xFF8C8C8C),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            ref.invalidate(schoolSearchProvider(_query));
                          },
                          child: Text('通用.重试'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _resolveSchoolName(SchoolVO school) {
    if (school.nameZh.trim().isNotEmpty) {
      return school.nameZh.trim();
    }
    if (school.nameEn.trim().isNotEmpty) {
      return school.nameEn.trim();
    }
    if ((school.nameLocal ?? '').trim().isNotEmpty) {
      return school.nameLocal!.trim();
    }
    if ((school.shortName ?? '').trim().isNotEmpty) {
      return school.shortName!.trim();
    }
    return '';
  }

  TextSpan _buildHighlightedText(String school, String keyword) {
    if (keyword.isEmpty || !school.contains(keyword)) {
      return TextSpan(
        text: school,
        style: const TextStyle(
          color: Color(0xFF171A1D),
          fontSize: 16,
          fontWeight: FontWeight.w400,
          height: 22 / 16,
        ),
      );
    }

    final List<TextSpan> children = <TextSpan>[];
    int start = 0;
    while (true) {
      final int matchIndex = school.indexOf(keyword, start);
      if (matchIndex < 0) {
        children.add(
          TextSpan(
            text: school.substring(start),
            style: const TextStyle(
              color: Color(0xFF171A1D),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 22 / 16,
            ),
          ),
        );
        break;
      }

      if (matchIndex > start) {
        children.add(
          TextSpan(
            text: school.substring(start, matchIndex),
            style: const TextStyle(
              color: Color(0xFF171A1D),
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 22 / 16,
            ),
          ),
        );
      }

      children.add(
        TextSpan(
          text: keyword,
          style: const TextStyle(
            color: Color(0xFF096DD9),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            height: 22 / 16,
          ),
        ),
      );
      start = matchIndex + keyword.length;
    }

    return TextSpan(children: children);
  }
}
