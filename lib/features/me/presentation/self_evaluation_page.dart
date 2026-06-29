import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:bluehub_app/shared/ui/test_style.dart';

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

  void _handleChanged() {
    setState(() {});
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _handleSave() {
    context.pop(_controller.text.trim());
  }

  void _toggleInputFocus() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
      return;
    }
    _focusNode.requestFocus();
  }

  void _dismissKeyboard() {
    if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final int currentLength = _controller.text.characters.length;
    final bool isKeyboardVisible = bottomInset > 0;

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
          '我的.自我评价'.tr(),
          style: TestStyle.pingFangMedium(
            fontSize: 17,
            color: Color(0xE6000000),
          ),
        ),
      ),
      body: Stack(
        children: <Widget>[
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: TextField(
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
          ),
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _toggleInputFocus,
              child: const SizedBox.expand(),
            ),
          ),
        ],
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
