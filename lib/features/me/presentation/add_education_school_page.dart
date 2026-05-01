import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class AddEducationSchoolPage extends StatefulWidget {
  const AddEducationSchoolPage({
    super.key,
    this.initialSchool,
  });

  final String? initialSchool;

  @override
  State<AddEducationSchoolPage> createState() => _AddEducationSchoolPageState();
}

class _AddEducationSchoolPageState extends State<AddEducationSchoolPage> {
  static const List<String> _schoolOptions = <String>[
    '南京大学金陵学院',
    '南京工业大学',
    '南京财经大学',
    '南京师范大学',
    '南京理工大学',
    '南京林业大学',
  ];

  late final TextEditingController _searchController = TextEditingController(
    text: _initialKeyword(widget.initialSchool),
  )..addListener(_handleSearchChanged);

  String? _selectedSchool;

  static String _initialKeyword(String? initialSchool) {
    if ((initialSchool ?? '').trim().isEmpty) {
      return '南京';
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
      if (_selectedSchool != null &&
          !_selectedSchool!.contains(_searchController.text.trim())) {
        _selectedSchool = null;
      }
    });
  }

  List<String> get _filteredSchools {
    final String keyword = _searchController.text.trim();
    if (keyword.isEmpty) {
      return _schoolOptions;
    }
    return _schoolOptions
        .where((String school) => school.contains(keyword))
        .toList(growable: false);
  }

  void _handleConfirm() {
    final String keyword = _searchController.text.trim();
    final List<String> filtered = _filteredSchools;
    final String? result = _selectedSchool ??
        (filtered.contains(keyword) ? keyword : null) ??
        (filtered.length == 1 ? filtered.first : null);

    if (result == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请选择学校')));
      return;
    }

    context.pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final List<String> schools = _filteredSchools;

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
        title: const Text(
          '学校',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: _handleConfirm,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF262626),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text(
              '确定',
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
                child: SizedBox(
                  height: 36,
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
                      decoration: const InputDecoration(
                        hintText: '请输入学校名称',
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
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: schools.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 16,
                    color: Color(0xFFF0F0F0),
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final String school = schools[index];
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedSchool = school;
                        });
                      },
                      child: Container(
                        height: 52,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: RichText(
                          text: _buildHighlightedText(
                            school,
                            _searchController.text.trim(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
