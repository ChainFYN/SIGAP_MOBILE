class ApiConstants {
  // IP Wi-Fi laptop Fedora Anda saat ini
  static const String baseUrl = 'http://10.10.16.171:8000/api';

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
