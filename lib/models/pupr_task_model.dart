class MaterialRealisasi {
  final String nama;
  final String rencanaSpk;
  double realisasi;
  final String satuan;
  final String iconType; // 'truck', 'barrel', 'aggregate'

  MaterialRealisasi({
    required this.nama,
    required this.rencanaSpk,
    required this.realisasi,
    required this.satuan,
    required this.iconType,
  });

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'rencana_spk': rencanaSpk,
        'realisasi': realisasi,
        'satuan': satuan,
        'icon_type': iconType,
      };

  factory MaterialRealisasi.fromJson(Map<String, dynamic> json) =>
      MaterialRealisasi(
        nama: json['nama'] ?? '',
        rencanaSpk: json['rencana_spk'] ?? '',
        realisasi: (json['realisasi'] as num?)?.toDouble() ?? 0.0,
        satuan: json['satuan'] ?? '',
        iconType: json['icon_type'] ?? 'truck',
      );
}

class SpkKantor {
  final String paguAnggaran;
  final String targetSelesai;
  final String sisaHariKerja;

  const SpkKantor({
    required this.paguAnggaran,
    required this.targetSelesai,
    required this.sisaHariKerja,
  });

  Map<String, dynamic> toJson() => {
        'pagu_anggaran': paguAnggaran,
        'target_selesai': targetSelesai,
        'sisa_hari_kerja': sisaHariKerja,
      };
}

enum TahapStatus { selesai, aktif, terkunci }

class TahapPekerjaanItem {
  final int tahap;
  final String judul;
  final int persen;
  final TahapStatus status;

  const TahapPekerjaanItem({
    required this.tahap,
    required this.judul,
    required this.persen,
    required this.status,
  });
}

class PuprTaskModel {
  final String id;
  final String judul;
  final String jalan;
  final String kecamatan;
  final String kabupaten;
  final String statusVerifikasi;
  final String statusBahaya;
  final String targetWaktu;
  final String titikKm;
  final double targetLat;
  final double targetLng;
  int progresPersen;
  String tahapAktif;
  int tahapKe;
  int totalTahap;
  String metodePenanganan;
  String volumeKerusakan;
  String catatanTeknis;
  List<MaterialRealisasi> materials;
  final SpkKantor spk;
  final String fotoAwalUrl;
  String? fotoProgresPath;
  String updateTerakhir;
  bool isDraft;

  PuprTaskModel({
    required this.id,
    required this.judul,
    required this.jalan,
    required this.kecamatan,
    required this.kabupaten,
    this.statusVerifikasi = 'Tervalidasi Admin PUPR',
    this.statusBahaya = 'DARURAT / AMBLES PARAH',
    this.targetWaktu = 'Hari Ini 17:00 WIB',
    this.titikKm = 'Titik KM 14+200 Sisi Kiri',
    this.targetLat = -8.1773,
    this.targetLng = 113.6938,
    this.progresPersen = 75,
    this.tahapAktif = 'Penghamparan Hotmix',
    this.tahapKe = 3,
    this.totalTahap = 4,
    this.metodePenanganan = 'Deep Patching & Hotmix Overlay',
    this.volumeKerusakan = '2.7 M³ (6m x 3m x 0.15m)',
    this.catatanTeknis =
        'Pondasi agregat A telah dipadatkan roller 8 ton. Cuaca cerah mendukung penghamparan hotmix.',
    required this.materials,
    required this.spk,
    this.fotoAwalUrl = 'assets/images/foto_awal_warga.jpg',
    this.fotoProgresPath,
    this.updateTerakhir = '16 Nov 2026, 14:41 WIB',
    this.isDraft = false,
  });

  PuprTaskModel copyWith({
    int? progresPersen,
    String? tahapAktif,
    int? tahapKe,
    String? metodePenanganan,
    String? volumeKerusakan,
    String? catatanTeknis,
    List<MaterialRealisasi>? materials,
    String? fotoProgresPath,
    String? updateTerakhir,
    bool? isDraft,
  }) {
    return PuprTaskModel(
      id: id,
      judul: judul,
      jalan: jalan,
      kecamatan: kecamatan,
      kabupaten: kabupaten,
      statusVerifikasi: statusVerifikasi,
      statusBahaya: statusBahaya,
      targetWaktu: targetWaktu,
      titikKm: titikKm,
      targetLat: targetLat,
      targetLng: targetLng,
      progresPersen: progresPersen ?? this.progresPersen,
      tahapAktif: tahapAktif ?? this.tahapAktif,
      tahapKe: tahapKe ?? this.tahapKe,
      totalTahap: totalTahap,
      metodePenanganan: metodePenanganan ?? this.metodePenanganan,
      volumeKerusakan: volumeKerusakan ?? this.volumeKerusakan,
      catatanTeknis: catatanTeknis ?? this.catatanTeknis,
      materials: materials ?? this.materials,
      spk: spk,
      fotoAwalUrl: fotoAwalUrl,
      fotoProgresPath: fotoProgresPath ?? this.fotoProgresPath,
      updateTerakhir: updateTerakhir ?? this.updateTerakhir,
      isDraft: isDraft ?? this.isDraft,
    );
  }
}
