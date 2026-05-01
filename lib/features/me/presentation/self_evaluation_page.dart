import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SelfEvaluationPage extends StatefulWidget {
  const SelfEvaluationPage({
    super.key,
    this.initialValue = '',
  });

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

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final int currentLength = _controller.text.characters.length;

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
          '自我评价',
          style: TextStyle(
            color: Color(0xE6000000),
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 24 / 17,
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
                      style: const TextStyle(
                        color: Color(0xFF171A1D),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 24 / 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: '请输入',
                        hintStyle: TextStyle(
                          color: Color(0xFFBFBFBF),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          height: 24 / 16,
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
                      style: const TextStyle(
                        color: Color(0xFF8C8C8C),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 20 / 14,
                      ),
                    ),
                  ),
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
                  child: const Text(
                    '保存',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 22 / 16,
                    ),
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
