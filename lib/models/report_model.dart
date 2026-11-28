import '../core/constants/api_constants.dart';

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

class ReportProgressItem {
  final String judul;
  final String catatan;
  final String? waktu;

  const ReportProgressItem({
    required this.judul,
    required this.catatan,
    this.waktu,
  });

  factory ReportProgressItem.fromJson(Map<String, dynamic> json) {
    final persen = json['persentase'] ?? json['progres_persen'];
    final metode = json['metode']?.toString();
    final catatanRaw =
        json['catatan']?.toString() ??
        json['deskripsi']?.toString() ??
        json['keterangan']?.toString() ??
        '-';
    final judulRaw =
        json['tahap']?.toString() ??
        json['judul']?.toString() ??
        (persen != null ? 'Progres $persen%' : 'Update Progres');

    final parts = <String>[
      if (persen != null && !judulRaw.contains('%')) 'Progres $persen%',
      if (metode != null && metode.isNotEmpty) 'Metode: $metode',
      catatanRaw,
    ];

    return ReportProgressItem(
      judul: judulRaw,
      catatan: parts.join(' • '),
      waktu: json['created_at']?.toString() ?? json['waktu']?.toString(),
    );
  }
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
  final String? verifikator;
  final String? catatanVerifikasi;
  final DateTime? verifiedAt;
  final List<ReportProgressItem> progresList;

  ReportModel({
    required this.id,
    this.kodeTiket = '',
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
    this.verifikator,
    this.catatanVerifikasi,
    this.verifiedAt,
    this.progresList = const [],
  });

  /// Mengubah JSON respons Laravel (LaporanResource) menjadi objek ReportModel
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final lokasi = json['lokasi'] as Map<String, dynamic>? ?? {};
    final kategoriObj = json['kategori'] as Map<String, dynamic>? ?? {};
    final statusObj = json['status'] as Map<String, dynamic>? ?? {};
    final koordinatObj = json['koordinat'] as Map<String, dynamic>? ?? {};
    final verifikasiObj = json['verifikasi'] as Map<String, dynamic>? ?? {};

    final lat = koordinatObj['latitude'];
    final lng = koordinatObj['longitude'];
    final strKoordinat = (lat != null && lng != null)
        ? '$lat, $lng'
        : 'GPS Terdata';

    DateTime tgl;
    if (json['created_at'] != null) {
      try {
        tgl = DateTime.parse(json['created_at'].toString());
      } catch (_) {
        tgl = DateTime.now();
      }
    } else {
      tgl = DateTime.now();
    }

    DateTime? tglVerifikasi;
    final rawVerifiedAt =
        verifikasiObj['verified_at'] ??
        verifikasiObj['created_at'] ??
        json['verified_at'];
    if (rawVerifiedAt != null) {
      tglVerifikasi = DateTime.tryParse(rawVerifiedAt.toString());
    }

    final rawProgres =
        (json['progres'] ?? json['riwayat_progres'] ?? json['progress_logs'])
            as List?;
    final progresItems = rawProgres == null
        ? const <ReportProgressItem>[]
        : rawProgres
              .whereType<Map<String, dynamic>>()
              .map(ReportProgressItem.fromJson)
              .toList();

    // Tangani URL foto agar tidak nyangkut di localhost
    String? rawFoto = json['foto_url']?.toString();
    if (rawFoto != null && rawFoto.contains('localhost:8000')) {
      // Ambil domain dari baseUrl (misal: http://192.168.1.77:8000 atau Ngrok)
      final host = ApiConstants.baseUrl.replaceAll('/api', '');
      rawFoto = rawFoto.replaceAll('http://localhost:8000', host);
    }

    // Format kode tiket LP-YYYY-0001 (identik dengan Laravel)
    final rawId = json['id']?.toString() ?? '0';
    final kodeOtomatis = 'LP-${tgl.year}-${rawId.padLeft(4, '0')}';

    return ReportModel(
      id: rawId,
      kodeTiket: json['kode_tiket']?.toString() ?? kodeOtomatis,
      kecamatan: lokasi['kecamatan']?.toString() ?? '-',
      desa: lokasi['desa']?.toString() ?? '-',
      jalanPatokan: lokasi['jalan']?.toString() ?? '-',
      koordinat: strKoordinat,
      kategori: kategoriObj['nama']?.toString() ?? 'Lainnya',
      tingkatBahaya: json['tingkat_bahaya']?.toString() ?? 'Sedang',
      deskripsi: json['deskripsi']?.toString() ?? '-',
      status: statusObj['nama']?.toString() ?? 'Menunggu',
      fotoUrl:
          rawFoto, // <-- Ganti baris ini dari json['foto_url'] menjadi rawFoto
      photos: [],
      createdAt: tgl,
      verifikator:
          verifikasiObj['oleh']?.toString() ??
          json['diverifikasi_oleh']?.toString(),
      catatanVerifikasi:
          verifikasiObj['catatan']?.toString() ??
          json['catatan_verifikasi']?.toString(),
      verifiedAt: tglVerifikasi,
      progresList: progresItems,
    );
  }
}
