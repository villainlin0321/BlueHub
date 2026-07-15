import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:europepass/shared/ui/test_keys.dart';
import 'package:europepass/shared/ui/test_style.dart';
import 'package:europepass/shared/widgets/tap_blank_to_dismiss_keyboard.dart';

class SelfEvaluationPage extends StatefulWidget {
  const SelfEvaluationPage({super.key, this.initialValue = ''});

  final String initialValue;

  @override
  State<SelfEvaluationPage> createState() => _SelfEvaluationPageState();
}

class _SelfEvaluationPageState extends State<SelfEvaluationPage> {
  static const int _maxLength = 500;

  final FocusNode _focusNode = FocusNode();
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  )..addListener(_handleChanged);

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller
      ..removeListener(_handleChanged)
      ..dispose();
    super.dispose();
  }

  /// 监听输入内容变化，驱动字数统计与保存结果刷新。
  void _handleChanged() {
    setState(() {});
  }

  /// 监听焦点变化，控制“完成”按钮等依赖焦点的界面状态。
  void _handleFocusChanged() {
    setState(() {});
  }

  /// 保存当前输入内容，并将修剪后的文本返回上一页。
  void _handleSave() {
    // 保存前统一去除首尾空白，避免将无意义空格回传给上游页面。
    context.pop(_controller.text.trim());
  }

  /// 输入框聚焦时主动收起键盘，避免底部操作后焦点被继续占用。
  void _dismissKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  /// 构建自我评价页可滚动内容区，并统一处理点击空白与拖动失焦。
  Widget _buildScrollableBody(BuildContext context) {
    final int currentLength = _controller.text.characters.length;
    final bool isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return SafeArea(
      top: false,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SizedBox(
              height: constraints.maxHeight,
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      key: AppTestKeys.fieldSelfEvaluationInput,
                      focusNode: _focusNode,
                      controller: _controller,
                      maxLength: _maxLength,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: TestStyle.pingFangRegular(
                        fontSize: 16,
                        color: Color(0xFF171A1D),
                      ),
                      decoration: InputDecoration(
                        hintText: '通用.请输入'.tr(),
                        hintStyle: TestStyle.pingFangRegular(
                          fontSize: 16,
                          color: Color(0xFFBFBFBF),
                        ),
                        border: InputBorder.none,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$currentLength/$_maxLength',
                      style: TestStyle.regular(
                        fontSize: 14,
                        color: Color(0xFF8C8C8C),
                      ),
                    ),
                  ),
                  if (isKeyboardVisible) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        key: AppTestKeys.actionSelfEvaluationDone,
                        onPressed: _dismissKeyboard,
                        style: TextButton.styleFrom(
                          minimumSize: Size.zero,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFF096DD9),
                        ),
                        child: Text(
                          '完成',
                          style: TestStyle.pingFangMedium(fontSize: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      key: AppTestKeys.pageSelfEvaluation,
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
          '我的.自我评价'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
      ),
      body: TapBlankToDismissKeyboard(
        // 页面级统一复用共享失焦能力，避免与自定义全屏手势层竞争。
        child: _buildScrollableBody(context),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset > 0 ? 12 : 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                height: 44,
                width: double.infinity,
                child: FilledButton(
                  key: AppTestKeys.actionSelfEvaluationSave,
                  onPressed: _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF096DD9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '我的.保存'.tr(),
                    style: TestStyle.pingFangRegular(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 33),
            ],
          ),
        ),
      ),
    );
  }
}
