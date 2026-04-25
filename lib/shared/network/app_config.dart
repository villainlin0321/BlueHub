import 'env.dart';

class AppConfig {
  const AppConfig({
    required this.env,
    required this.baseUrl,
  });

  final AppEnv env;
  final String baseUrl;

  static AppConfig fromEnvironment() {
    const envRaw = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final env = AppEnv.parse(envRaw);

    const overrideBaseUrl = String.fromEnvironment('APP_BASE_URL', defaultValue: '');
    if (overrideBaseUrl.trim().isNotEmpty) {
      return AppConfig(env: env, baseUrl: overrideBaseUrl.trim());
    }

    switch (env) {
      case AppEnv.dev:
        return const AppConfig(env: AppEnv.dev, baseUrl: 'http://39.101.190.245:8090');
      case AppEnv.prod:
        return const AppConfig(env: AppEnv.prod, baseUrl: 'https://api.XXX.com');
    }
  }
}

