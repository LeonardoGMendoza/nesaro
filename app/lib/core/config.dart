/// Configuração do app, passada na hora de rodar:
///   flutter run --dart-define=NESARO_API_URL=https://api.nesaro.com.br
class AppConfig {
  const AppConfig._();

  /// 10.0.2.2 é o "localhost" do seu PC visto de dentro do emulador Android.
  static const apiBaseUrl = String.fromEnvironment(
    'NESARO_API_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );
}
