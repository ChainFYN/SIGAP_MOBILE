import 'package:flutter/material.dart';
import '../models/pupr_task_model.dart';
import '../services/pupr_service.dart';

class PuprFormProgresPage extends StatefulWidget {
  final PuprTaskModel task;

  const PuprFormProgresPage({super.key, required this.task});

  @override
  State<PuprFormProgresPage> createState() => _PuprFormProgresPageState();
}

class _PuprFormProgresPageState extends State<PuprFormProgresPage> {
  final _formKey = GlobalKey<FormState>();

  // State Tahapan Progres
  late int _selectedTahapKe;
  late int _selectedPersen;
  late String _selectedTahapNama;

  // Controllers
  late TextEditingController _catatanController;
  late TextEditingController _volumeController;
  late String _selectedMetode;

  // Controllers Material Terpakai
  late TextEditingController _aspalController;
  late TextEditingController _emulsiController;
  late TextEditingController _agregatController;

  // Foto Progres
  String? _fotoProgresPath;
  bool _isLoading = false;

  final List<String> _metodeList = [
    'Deep Patching & Hotmix Overlay',
    'Levelling & Cold Mix',
    'Rekonstruksi Base & Surface',
    'Grouting & Seal Coat',
  ];

  @override
  void initState() {
    super.initState();
    _selectedTahapKe = widget.task.tahapKe;
    _selectedPersen = widget.task.progresPersen;
    _selectedTahapNama = widget.task.tahapAktif;

    _catatanController = TextEditingController(text: widget.task.catatanTeknis);
    _volumeController = TextEditingController(
      text: widget.task.volumeKerusakan,
    );
    _selectedMetode = widget.task.metodePenanganan;

    _aspalController = TextEditingController(
      text: widget.task.materials.isNotEmpty
          ? widget.task.materials[0].realisasi.toString()
          : '2.8',
    );
    _emulsiController = TextEditingController(
      text: widget.task.materials.length > 1
          ? widget.task.materials[1].realisasi.toInt().toString()
          : '35',
    );
    _agregatController = TextEditingController(
      text: widget.task.materials.length > 2
          ? widget.task.materials[2].realisasi.toString()
          : '3.0',
    );

    _fotoProgresPath = widget.task.fotoProgresPath;
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _volumeController.dispose();
    _aspalController.dispose();
    _emulsiController.dispose();
    _agregatController.dispose();
    super.dispose();
  }

  void _onSelectTahap(int tahap, int persen, String nama) {
    if (tahap == 4) {
      // Validasi Dialog Konfirmasi BAST untuk 100%
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(
                Icons.assignment_turned_in_rounded,
                color: Color(0xFFEA580C),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Konfirmasi Tahap 100% (BAST)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Text(
            'Memilih Tahap 4 (100%) menandakan bahwa seluruh pengerjaan fisik di lapangan telah tuntas sempurna dan siap diajukan untuk penerbitan BAST (Berita Acara Serah Terima) oleh PPK / Pengawas Dinas PUPR.\n\nApakah Anda yakin fisik pengerjaan telah selesai 100%?',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Color(0xFF334155),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _selectedTahapKe = 4;
                  _selectedPersen = 100;
                  _selectedTahapNama = 'Selesai & Publikasi Progres';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Ya, Selesai 100%'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _selectedTahapKe = tahap;
      _selectedPersen = persen;
      _selectedTahapNama = nama;
    });
  }

  void _ambilFotoKamera() {
    // Simulasi pengambilan gambar kamera lapangan dengan kompresi otomatis
    setState(() {
      _fotoProgresPath =
          'foto_progres_lapangan_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto kamera berhasil diambil & dikompresi (1.1 MB).'),
        backgroundColor: Color(0xFF059669),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _submitProgres() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Susun material yang diperbarui
    final updatedMaterials = [
      MaterialRealisasi(
        nama: 'Aspal Hotmix Laston AC-WC',
        rencanaSpk: 'Rencana SPK: 3.2 Ton',
        realisasi: double.tryParse(_aspalController.text) ?? 2.8,
        satuan: 'Ton',
        iconType: 'truck',
      ),
      MaterialRealisasi(
        nama: 'Emulsi Tack Coat CRS-1',
        rencanaSpk: 'Rencana SPK: 40 Liter',
        realisasi: double.tryParse(_emulsiController.text) ?? 35.0,
        satuan: 'Liter',
        iconType: 'barrel',
      ),
      MaterialRealisasi(
        nama: 'Lapis Pondasi Agregat Kelas A',
        rencanaSpk: 'Rencana SPK: 3.0 M³',
        realisasi: double.tryParse(_agregatController.text) ?? 3.0,
        satuan: 'M³',
        iconType: 'aggregate',
      ),
    ];

    final success = await PuprService.submitProgres(
      taskId: widget.task.id,
      persentase: _selectedPersen,
      tahap: _selectedTahapNama,
      tahapKe: _selectedTahapKe,
      catatan: _catatanController.text.trim(),
      metodePenanganan: _selectedMetode,
      volumeKerusakan: _volumeController.text.trim(),
      materials: updatedMaterials,
      fotoProgresPath: _fotoProgresPath,
    );

    setState(() => _isLoading = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Progres fisik lapangan berhasil dipublikasikan ke REST API!',
                ),
              ),
            ],
          ),
          backgroundColor: Color(0xFF059669),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _simpanDraf() async {
    final updatedMaterials = [
      MaterialRealisasi(
        nama: 'Aspal Hotmix Laston AC-WC',
        rencanaSpk: 'Rencana SPK: 3.2 Ton',
        realisasi: double.tryParse(_aspalController.text) ?? 2.8,
        satuan: 'Ton',
        iconType: 'truck',
      ),
      MaterialRealisasi(
        nama: 'Emulsi Tack Coat CRS-1',
        rencanaSpk: 'Rencana SPK: 40 Liter',
        realisasi: double.tryParse(_emulsiController.text) ?? 35.0,
        satuan: 'Liter',
        iconType: 'barrel',
      ),
      MaterialRealisasi(
        nama: 'Lapis Pondasi Agregat Kelas A',
        rencanaSpk: 'Rencana SPK: 3.0 M³',
        realisasi: double.tryParse(_agregatController.text) ?? 3.0,
        satuan: 'M³',
        iconType: 'aggregate',
      ),
    ];

    await PuprService.saveDraft(
      taskId: widget.task.id,
      persentase: _selectedPersen,
      tahap: _selectedTahapNama,
      catatan: _catatanController.text.trim(),
      metodePenanganan: _selectedMetode,
      volumeKerusakan: _volumeController.text.trim(),
      materials: updatedMaterials,
      fotoProgresPath: _fotoProgresPath,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Draf berhasil disimpan di memori lokal perangkat (Offline Cache).',
          ),
          backgroundColor: Color(0xFF0A1D37),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Log Progres Lapangan',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF64748B),
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Ringkasan Tugas
              _buildTaskHeaderCard(),
              const SizedBox(height: 14),

              // 2. Form Update Log Progres Lapangan (Stepper & Catatan)
              _buildStepperSection(),
              const SizedBox(height: 14),

              // 3. Spesifikasi Teknis (Metode, Dimensi, Material & SPK)
              _buildSpesifikasiTeknisSection(),
              const SizedBox(height: 14),

              // 4. Komparasi Visual Pengerjaan (Kamera & Foto Warga)
              _buildVisualComparisonSection(),
              const SizedBox(height: 14),

              // 5. Banner Offline-First
              _buildOfflineBanner(),
              const SizedBox(height: 18),

              // 6. Tombol Aksi
              _buildActionButtons(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // === 1. HEADER RINGKASAN TUGAS ===
  Widget _buildTaskHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge Status Pekerjaan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.engineering_rounded,
                  size: 14,
                  color: Color(0xFFD97706),
                ),
                SizedBox(width: 5),
                Text(
                  'SEDANG DIKERJAKAN PUPR',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.task.judul,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.task.kecamatan}, ${widget.task.kabupaten}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'Update Terakhir: ${widget.task.updateTerakhir}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === 2. STATUS TAHAPAN PEKERJAAN (SEQUENTIAL STEPPER) ===
  Widget _buildStepperSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: const [
              Icon(
                Icons.assignment_turned_in_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Form Update Log Progres Lapangan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Subtitle Status Tahapan
          const Text(
            'STATUS TAHAPAN PEKERJAAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 10),

          // 4 Sequential Steppers
          _buildStepItem(
            tahap: 1,
            persen: 25,
            judul: 'Tahap 1: Pengecekan Lokasi (25%)',
            status: _selectedTahapKe > 1
                ? TahapStatus.selesai
                : (_selectedTahapKe == 1
                      ? TahapStatus.aktif
                      : TahapStatus.terkunci),
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            tahap: 2,
            persen: 50,
            judul: 'Tahap 2: Persiapan Material & Alat (50%)',
            status: _selectedTahapKe > 2
                ? TahapStatus.selesai
                : (_selectedTahapKe == 2
                      ? TahapStatus.aktif
                      : TahapStatus.terkunci),
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            tahap: 3,
            persen: 75,
            judul: 'Tahap 3: Pengerjaan Fisik / Eksekusi (75%)',
            status: _selectedTahapKe > 3
                ? TahapStatus.selesai
                : (_selectedTahapKe == 3
                      ? TahapStatus.aktif
                      : TahapStatus.terkunci),
          ),
          const SizedBox(height: 8),
          _buildStepItem(
            tahap: 4,
            persen: 100,
            judul: 'Tahap 4: Selesai & Publikasi Progres (100%)',
            status: _selectedTahapKe == 4
                ? TahapStatus.aktif
                : TahapStatus.terkunci,
          ),

          const SizedBox(height: 16),

          // Catatan Teknis Lapangan
          const Text(
            'CATATAN TEKNIS LAPANGAN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _catatanController,
            maxLines: 3,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              hintText:
                  'Ketik detail pengerjaan, kendala cuaca, atau informasi material yang digunakan di sini...',
              hintStyle: const TextStyle(
                fontSize: 12,
                color: Color(0xFF94A3B8),
              ),
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: Color(0xFF0A1D37),
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required int tahap,
    required int persen,
    required String judul,
    required TahapStatus status,
  }) {
    Color bgColor;
    Color borderColor;
    Widget icon;
    Widget badge;

    switch (status) {
      case TahapStatus.selesai:
        bgColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFFBBF7D0);
        icon = const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF16A34A),
          size: 18,
        );
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Selesai',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF16A34A),
            ),
          ),
        );
        break;

      case TahapStatus.aktif:
        bgColor = Colors.white;
        borderColor = const Color(0xFF0A1D37);
        icon = const Icon(
          Icons.radio_button_checked_rounded,
          color: Color(0xFF0A1D37),
          size: 18,
        );
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF3C7),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Aktif',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD97706),
            ),
          ),
        );
        break;

      case TahapStatus.terkunci:
        bgColor = const Color(0xFFF8FAFC);
        borderColor = const Color(0xFFE2E8F0);
        icon = const Icon(
          Icons.radio_button_off_rounded,
          color: Color(0xFF94A3B8),
          size: 18,
        );
        badge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'Terkunci',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
            ),
          ),
        );
        break;
    }

    return InkWell(
      onTap: () => _onSelectTahap(tahap, persen, judul),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: borderColor,
            width: status == TahapStatus.aktif ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                judul,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: status == TahapStatus.aktif
                      ? FontWeight.bold
                      : FontWeight.w600,
                  color: status == TahapStatus.terkunci
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                ),
              ),
            ),
            badge,
          ],
        ),
      ),
    );
  }

  // === 3. SPESIFIKASI TEKNIS ===
  Widget _buildSpesifikasiTeknisSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Spesifikasi Teknis
          Row(
            children: const [
              Icon(Icons.settings_outlined, size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Spesifikasi Teknis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metode Penanganan Dropdown
          const Text(
            'Metode Penanganan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _selectedMetode,
            isExpanded: true,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            items: _metodeList
                .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedMetode = val);
            },
          ),

          const SizedBox(height: 12),

          // Volume Kerusakan & Dimensi
          const Text(
            'Volume Kerusakan & Dimensi',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _volumeController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),

          const SizedBox(height: 16),

          // Realisasi Material Terpakai Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'REALISASI MATERIAL TERPAKAI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Input Mandor Lapangan',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Item 1: Aspal
          _buildMaterialInputItem(
            icon: Icons.local_shipping_outlined,
            title: 'Aspal Hotmix Laston AC-WC',
            subtitle: 'Rencana SPK: 3.2 Ton',
            controller: _aspalController,
            unit: 'Ton',
          ),
          const SizedBox(height: 8),

          // Item 2: Emulsi Tack Coat
          _buildMaterialInputItem(
            icon: Icons.water_drop_outlined,
            title: 'Emulsi Tack Coat CRS-1',
            subtitle: 'Rencana SPK: 40 Liter',
            controller: _emulsiController,
            unit: 'Liter',
          ),
          const SizedBox(height: 8),

          // Item 3: Agregat A
          _buildMaterialInputItem(
            icon: Icons.terrain_outlined,
            title: 'Lapis Pondasi Agregat Kelas A',
            subtitle: 'Rencana SPK: 3.0 M³',
            controller: _agregatController,
            unit: 'M³',
          ),

          const SizedBox(height: 16),

          // Ketetapan DPA/SPK Kantor Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KETETAPAN DPA/SPK KANTOR',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'READ-ONLY',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 2 Read-Only SPK Cards
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Pagu Anggaran',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.task.spk.paguAnggaran,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tercatat di SPK/DPA PUPR',
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F9FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBAE6FD)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Target Selesai SPK',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: Color(0xFF0F172A),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.task.spk.targetSelesai,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.task.spk.sisaHariKerja,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialInputItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF64748B)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 65,
            height: 38,
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              unit,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 4. KOMPARASI VISUAL PENGERJAAN ===
  Widget _buildVisualComparisonSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Komparasi Visual Pengerjaan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Kolom Kiri: Kamera Langsung Lapangan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kamera Langsung Lapangan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _ambilFotoKamera,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 125,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF10B981),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _fotoProgresPath != null
                            ? Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF10B981),
                                          size: 32,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Foto Tersimpan',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF065F46),
                                          ),
                                        ),
                                        Text(
                                          'Klik untuk ganti',
                                          style: TextStyle(
                                            fontSize: 9,
                                            color: Color(0xFF047857),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF065F46),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '1.1 MB',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.camera_alt_outlined,
                                    color: Color(0xFF10B981),
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Ambil Foto Progres',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Kompresi Otomatis (Maks 1.2MB)',
                                    style: TextStyle(
                                      fontSize: 8,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF065F46),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Wajib Kamera',
                                      style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Kolom Kanan: Foto Awal Lapangan (Warga)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Foto Awal Lapangan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 125,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              size: 36,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Positioned(
                            bottom: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1D37),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Awal (Warga)',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === 5. BANNER OFFLINE-FIRST ===
  Widget _buildOfflineBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.save_outlined, size: 18, color: Color(0xFF0A1D37)),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Mode Offline-First Aktif: Draf tersimpan di penyimpanan lokal perangkat (Hive/SQLite) & otomatis sinkron saat sinyal 4G/WiFi kembali stabil.',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF334155),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // === 6. TOMBOL EKSEKUSI ===
  Widget _buildActionButtons() {
    return Column(
      children: [
        // Tombol Utama: Oranye
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitProgres,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Simpan & Publikasikan Progres Lapangan',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol Sekunder: Outlined Simpan Draf
        SizedBox(
          width: double.infinity,
          height: 46,
          child: OutlinedButton.icon(
            onPressed: _simpanDraf,
            icon: const Icon(
              Icons.description_outlined,
              size: 18,
              color: Color(0xFF0A1D37),
            ),
            label: const Text(
              'Simpan Draf',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0A1D37),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
