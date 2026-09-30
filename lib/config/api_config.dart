/// Konfigurasi koneksi ke backend Smart Kantin Kampus (Laravel).
///
/// Base URL bisa diganti saat build tanpa mengubah kode:
///
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
class ApiConfig {
  const ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-kantin.7sic4.online/api',
  );

  static const Duration timeout = Duration(seconds: 20);
}
