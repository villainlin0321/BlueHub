import 'package:europepass/shared/network/app_result_error_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('优先使用后端返回的自然语言 message', () {
    expect(
      AppResultErrorResolver.resolve(code: 30002, message: '本月已投递过该岗位'),
      '本月已投递过该岗位',
    );
  });

  test('message 为 i18n key 时走业务码兜底', () {
    expect(
      AppResultErrorResolver.resolve(
        code: 70002,
        message: 'error.ai.rate.limit',
      ),
      'AI 对话频次受限（每天/每分钟）',
    );
  });

  test('message 为空且无业务码兜底时回退为通用业务异常', () {
    expect(
      AppResultErrorResolver.resolve(code: 29999, message: '   '),
      '通用.业务异常',
    );
  });
}
