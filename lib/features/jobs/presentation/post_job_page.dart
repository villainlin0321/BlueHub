import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/widgets/tap_blank_to_dismiss_keyboard.dart';
import 'post_job_page_styles.dart';
import 'widgets/post_job_form_widgets.dart';

class PostJobPage extends StatefulWidget {
  const PostJobPage({super.key});

  @override
  State<PostJobPage> createState() => _PostJobPageState();
}

class _PostJobPageState extends State<PostJobPage> {
  static const List<String> _jobTypes = <String>['不限', '全职', '兼职'];
  static const List<String> _salaryUnits = <String>['月薪', '周薪', '日薪', '时薪'];
  static const List<String> _requirementTags = <String>[
    '不限经验',
    '1~3年经验',
    '3-5年经验',
    '厨师证高级',
    '德语A2',
    '英语流利',
  ];

  final TextEditingController _packageNameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _headcountController = TextEditingController();
  final TextEditingController _minSalaryController = TextEditingController();
  final TextEditingController _maxSalaryController = TextEditingController();
  final TextEditingController _customTagController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedJobType = _jobTypes.first;
  String _selectedSalaryUnit = _salaryUnits.first;
  final Set<String> _selectedRequirementTags = <String>{
    '不限经验',
    '1~3年经验',
    '德语A2',
  };
  int _descriptionLength = 0;

  @override
  void dispose() {
    _packageNameController.dispose();
    _countryController.dispose();
    _headcountController.dispose();
    _minSalaryController.dispose();
    _maxSalaryController.dispose();
    _customTagController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _toggleRequirementTag(String value) {
    setState(() {
      if (_selectedRequirementTags.contains(value)) {
        _selectedRequirementTags.remove(value);
      } else {
        _selectedRequirementTags.add(value);
      }
    });
  }

  void _saveDraft() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('草稿已保存')));
  }

  void _publish() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('立即发布已触发')));
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: PostJobPageStyles.pageBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: SvgPicture.asset(
            'assets/images/service_detail_back.svg',
            width: 12,
            height: 24,
            colorFilter: const ColorFilter.mode(
              Color(0xE6000000),
              BlendMode.srcIn,
            ),
          ),
        ),
        title: const Text('发布岗位', style: PostJobPageStyles.navTitle),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton(
              onPressed: _saveDraft,
              style: TextButton.styleFrom(
                minimumSize: const Size(44, 32),
                foregroundColor: PostJobPageStyles.titleText,
                textStyle: PostJobPageStyles.navAction,
              ),
              child: const Text('存草稿'),
            ),
          ),
        ],
      ),
      body: TapBlankToDismissKeyboard(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double contentWidth = constraints.maxWidth.clamp(0, 560);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: contentWidth,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  child: Column(
                    children: <Widget>[
                      PostJobSectionCard(
                        title: '基础信息',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            PostJobFieldGroup(
                              label: '套餐名称',
                              child: PostJobInputField(
                                controller: _packageNameController,
                                hintText: '例如：中餐厨师',
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '服务国家',
                              child: PostJobInputField(
                                controller: _countryController,
                                hintText: '如：德国柏林',
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '招聘类型',
                              child: Wrap(
                                spacing: 0,
                                runSpacing: 12,
                                children: _jobTypes
                                    .map(
                                      (String item) => PostJobRadioOption(
                                        label: item,
                                        selected: item == _selectedJobType,
                                        onTap: () {
                                          setState(() {
                                            _selectedJobType = item;
                                          });
                                        },
                                      ),
                                    )
                                    .toList(growable: false),
                              ),
                            ),
                            const SizedBox(height: 20),
                            PostJobFieldGroup(
                              label: '招聘人数',
                              child: PostJobInputField(
                                controller: _headcountController,
                                hintText: '请输入数字',
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                              ),
                            ),
                            const SizedBox(height: 16),
                            PostJobFieldGroup(
                              label: '薪资范围 (€)',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Wrap(
                                    spacing: 0,
                                    runSpacing: 12,
                                    children: _salaryUnits
                                        .map(
                                          (String item) => PostJobRadioOption(
                                            label: item,
                                            selected:
                                                item == _selectedSalaryUnit,
                                            onTap: () {
                                              setState(() {
                                                _selectedSalaryUnit = item;
                                              });
                                            },
                                          ),
                                        )
                                        .toList(growable: false),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: PostJobInputField(
                                          controller: _minSalaryController,
                                          hintText: '最低薪资',
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Text(
                                        '至',
                                        style: PostJobPageStyles.fieldLabel,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: PostJobInputField(
                                          controller: _maxSalaryController,
                                          hintText: '最高薪资',
                                          keyboardType: TextInputType.number,
                                          textInputAction: TextInputAction.next,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PostJobSectionCard(
                        title: '任职要求',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Wrap(
                              spacing: 8,
                              runSpacing: 12,
                              children: _requirementTags
                                  .map(
                                    (String tag) => SizedBox(
                                      width: 104,
                                      child: PostJobSelectableChip(
                                        label: tag,
                                        selected: _selectedRequirementTags
                                            .contains(tag),
                                        onTap: () => _toggleRequirementTag(tag),
                                      ),
                                    ),
                                  )
                                  .toList(growable: false),
                            ),
                            const SizedBox(height: 12),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: PostJobPageStyles.inputFill,
                                borderRadius: BorderRadius.circular(
                                  PostJobPageStyles.fieldRadius,
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(12, 14, 12, 14),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '回国探亲机票',
                                    style: PostJobPageStyles.fieldLabel,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            PostJobInputField(
                              controller: _customTagController,
                              hintText: '+ 自定义标签（如：回国探亲机票）8个字',
                              maxLength: 8,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PostJobSectionCard(
                        title: '工作描述',
                        trailing: const Text(
                          '选填',
                          style: PostJobPageStyles.optional,
                        ),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: PostJobPageStyles.inputFill,
                            borderRadius: BorderRadius.circular(
                              PostJobPageStyles.fieldRadius,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Column(
                              children: <Widget>[
                                TextField(
                                  controller: _descriptionController,
                                  maxLength: 200,
                                  maxLines: 5,
                                  minLines: 5,
                                  textInputAction: TextInputAction.done,
                                  onChanged: (String value) {
                                    setState(() {
                                      _descriptionLength =
                                          value.characters.length;
                                    });
                                  },
                                  buildCounter:
                                      (
                                        BuildContext context, {
                                        required int currentLength,
                                        required bool isFocused,
                                        required int? maxLength,
                                      }) {
                                        return const SizedBox.shrink();
                                      },
                                  style: PostJobPageStyles.optionText,
                                  decoration: const InputDecoration(
                                    hintText: '请详细描述工作内容、排版情况等...',
                                    hintStyle: PostJobPageStyles.placeholder,
                                    border: InputBorder.none,
                                    isCollapsed: true,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '$_descriptionLength/200',
                                    style: PostJobPageStyles.counter,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20 + bottomInset),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: PostJobPageStyles.divider)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton(
                  onPressed: _publish,
                  style: FilledButton.styleFrom(
                    backgroundColor: PostJobPageStyles.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        PostJobPageStyles.buttonRadius,
                      ),
                    ),
                  ),
                  child: const Text(
                    '立即发布',
                    style: PostJobPageStyles.buttonText,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
