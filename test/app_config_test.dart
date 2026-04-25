import 'package:flutter_test/flutter_test.dart';

import 'package:bluehub_app/shared/network/env.dart';

void main() {
  test('AppEnv.parse', () {
    expect(AppEnv.parse('dev'), AppEnv.dev);
    expect(AppEnv.parse('prod'), AppEnv.prod);
    expect(AppEnv.parse('production'), AppEnv.prod);
    expect(AppEnv.parse(''), AppEnv.dev);
  });
}

