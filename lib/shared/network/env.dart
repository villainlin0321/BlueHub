enum AppEnv {
  dev,
  prod;

  static AppEnv parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'prod':
      case 'production':
        return AppEnv.prod;
      case 'dev':
      case 'development':
      default:
        return AppEnv.dev;
    }
  }
}
