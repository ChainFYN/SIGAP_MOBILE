import 'package:flutter/foundation.dart';
import '../models/pupr_task_model.dart';
import 'location_nav_service.dart';

class PuprService {
  // Profil Tim Lapangan
  static const String namaTim = 'Tim Lapangan 1';
  static const String wilayah = 'Wilayah Pemeliharaan Jember';
  static const String roleLabel = 'REGU OPERASIONAL LAPANGAN';

  // State Reaktif untuk Tugas Aktif
  static final ValueNotifier<List<PuprTaskModel>> tasksNotifier =
      ValueNotifier<List<PuprTaskModel>>([
    PuprTaskModel(
      id: 'TGS-2026-0412',
      judul: 'Detail Penanganan Lapangan: Jl. Tidar',
      jalan: 'Jl. Tidar',
      kecamatan: 'Kec. Patrang',
      kabupaten: 'Kab. Jember',
      statusVerifikasi: 'Tervalidasi Admin PUPR',
      statusBahaya: 'DARURAT / AMBLES PARAH',
      targetWaktu: 'Hari Ini 17:00 WIB',
      titikKm: 'Titik KM 14+200 Sisi Kiri',
      targetLat: -8.1773,
      targetLng: 113.6938,
      progresPersen: 75,
      tahapAktif: 'Penghamparan Hotmix',
      tahapKe: 3,
      totalTahap: 4,
      metodePenanganan: 'Deep Patching & Hotmix Overlay',
      volumeKerusakan: '2.7 M³ (6m x 3m x 0.15m)',
      catatanTeknis:
          'Pondasi agregat A telah dipadatkan roller 8 ton. Cuaca cerah mendukung penghamparan hotmix.',
      materials: [
        MaterialRealisasi(
          nama: 'Aspal Hotmix Laston AC-WC',
          rencanaSpk: 'Rencana SPK: 3.2 Ton',
          realisasi: 2.8,
          satuan: 'Ton',
          iconType: 'truck',
        ),
        MaterialRealisasi(
          nama: 'Emulsi Tack Coat CRS-1',
          rencanaSpk: 'Rencana SPK: 40 Liter',
          realisasi: 35.0,
          satuan: 'Liter',
          iconType: 'barrel',
        ),
        MaterialRealisasi(
          nama: 'Lapis Pondasi Agregat Kelas A',
          rencanaSpk: 'Rencana SPK: 3.0 M³',
          realisasi: 3.0,
          satuan: 'M³',
          iconType: 'aggregate',
        ),
      ],
      spk: const SpkKantor(
        paguAnggaran: 'Rp 8.450.000',
        targetSelesai: '18 Nov 2026',
        sisaHariKerja: 'Sisa 2 Hari Kerja',
      ),
      fotoAwalUrl: 'assets/images/foto_awal_warga.jpg',
      updateTerakhir: '16 Nov 2026, 14:41 WIB',
      isDraft: false,
    ),
  ]);

  // KPI Counter
  static int get countDikerjakan =>
      tasksNotifier.value.where((t) => t.progresPersen < 100).length;
  static int get countDisposisi => 0;
  static int get countPekanIni => 1;

  // Draf Lokal (Offline-first cache)
  static final Map<String, Map<String, dynamic>> _offlineDrafts = {};

  static PuprTaskModel? getPrimaryTask() {
    if (tasksNotifier.value.isEmpty) return null;
    return tasksNotifier.value.first;
  }

  /// Menghitung jarak GPS saat ini ke titik tugas
  static double getDistanceToTask(PuprTaskModel task) {
    return LocationNavService.calculateDistanceMeters(
      lat1: LocationNavService.currentLat,
      lon1: LocationNavService.currentLng,
      lat2: task.targetLat,
      lon2: task.targetLng,
    );
  }

  /// Update progres lapangan & sinkronisasi ke server (atau simulasi REST API)
  static Future<bool> submitProgres({
    required String taskId,
    required int persentase,
    required String tahap,
    required int tahapKe,
    required String catatan,
    required String metodePenanganan,
    required String volumeKerusakan,
    required List<MaterialRealisasi> materials,
    String? fotoProgresPath,
  }) async {
    // Simulasi network latency HTTP POST
    await Future.delayed(const Duration(milliseconds: 600));

    final currentTasks = List<PuprTaskModel>.from(tasksNotifier.value);
    final index = currentTasks.indexWhere((t) => t.id == taskId);

    if (index != -1) {
      final updated = currentTasks[index].copyWith(
        progresPersen: persentase,
        tahapAktif: tahap,
        tahapKe: tahapKe,
        catatanTeknis: catatan,
        metodePenanganan: metodePenanganan,
        volumeKerusakan: volumeKerusakan,
        materials: materials,
        fotoProgresPath: fotoProgresPath ?? currentTasks[index].fotoProgresPath,
        updateTerakhir: 'Baru saja',
        isDraft: false,
      );
      currentTasks[index] = updated;
      tasksNotifier.value = currentTasks;
      _offlineDrafts.remove(taskId); // Hapus draf karena sudah tersimpan publik
      return true;
    }
    return false;
  }

  /// Menyimpan Draf ke local storage (Offline-first)
  static Future<bool> saveDraft({
    required String taskId,
    required int persentase,
    required String tahap,
    required String catatan,
    required String metodePenanganan,
    required String volumeKerusakan,
    required List<MaterialRealisasi> materials,
    String? fotoProgresPath,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _offlineDrafts[taskId] = {
      'taskId': taskId,
      'persentase': persentase,
      'tahap': tahap,
      'catatan': catatan,
      'metodePenanganan': metodePenanganan,
      'volumeKerusakan': volumeKerusakan,
      'materials': materials.map((m) => m.toJson()).toList(),
      'fotoProgresPath': fotoProgresPath,
      'timestamp': DateTime.now().toIso8601String(),
    };
    return true;
  }

  static bool hasDraft(String taskId) => _offlineDrafts.containsKey(taskId);
}
