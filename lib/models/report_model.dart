class ReportPhoto {
  final String fileName;
  final String size;
  final String tag;
  final String time;

  ReportPhoto({
    required this.fileName,
    required this.size,
    required this.tag,
    required this.time,
  });
}

class ReportModel {
  final String id;
  final String kodeTiket;
  final String kecamatan;
  final String desa;
  final String jalanPatokan;
  final String koordinat;
  final String kategori;
  final String tingkatBahaya;
  final String deskripsi;
  final String? status;
  final String? fotoUrl;
  final List<ReportPhoto> photos;
  final DateTime createdAt;

  ReportModel({
    required this.id,
    required this.kodeTiket,
    required this.kecamatan,
    required this.desa,
    required this.jalanPatokan,
    required this.koordinat,
    required this.kategori,
    required this.tingkatBahaya,
    required this.deskripsi,
    this.status = 'Menunggu Validasi',
    this.fotoUrl,
    required this.photos,
    required this.createdAt,
  });

  /// Mengubah JSON respons Laravel (LaporanResource) menjadi objek ReportModel
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final lokasi = json['lokasi'] as Map<String, dynamic>? ?? {};
    final kategoriObj = json['kategori'] as Map<String, dynamic>? ?? {};
    final statusObj = json['status'] as Map<String, dynamic>? ?? {};
    final koordinatObj = json['koordinat'] as Map<String, dynamic>? ?? {};

    final lat = koordinatObj['latitude'];
    final lng = koordinatObj['longitude'];
    final strKoordinat = (lat != null && lng != null)
        ? '$lat, $lng'
        : 'GPS Terdata';

    DateTime tgl;
    try {
      tgl = DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      );
    } catch (_) {
      tgl = DateTime.now();
    }

    return ReportModel(
      id: json['id']?.toString() ?? '',
      kodeTiket: json['kode_tiket']?.toString() ?? 'LP-${json['id']}',
      kecamatan: lokasi['kecamatan']?.toString() ?? '-',
      desa: lokasi['desa']?.toString() ?? '-',
      jalanPatokan: lokasi['jalan']?.toString() ?? '-',
      koordinat: strKoordinat,
      kategori: kategoriObj['nama']?.toString() ?? 'Lainnya',
      tingkatBahaya: json['tingkat_bahaya']?.toString() ?? 'Sedang',
      deskripsi: json['deskripsi']?.toString() ?? '-',
      status: statusObj['nama']?.toString() ?? 'Menunggu',
      fotoUrl: json['foto_url']?.toString(),
      photos: [],
      createdAt: tgl,
    );
  }
}
