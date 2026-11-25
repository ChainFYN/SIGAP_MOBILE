class ApiConstants {
  // Endpoint API melalui Ngrok
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://unbraided-greeter-giddy.ngrok-free.dev/api',
  );

  // Endpoint Auth
  static const String login = '$baseUrl/login';
  static const String register = '$baseUrl/register';

  // Endpoint Master Data
  static const String kecamatan = '$baseUrl/kecamatan';
  static const String desa = '$baseUrl/desa';
  static const String jalan = '$baseUrl/jalan';
  static const String kategori = '$baseUrl/kategori';

  // Endpoint Laporan
  static const String laporan = '$baseUrl/laporan';
}
