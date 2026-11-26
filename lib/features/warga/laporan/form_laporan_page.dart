import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';

class FormLaporanPage extends StatefulWidget {
  const FormLaporanPage({super.key});

  @override
  State<FormLaporanPage> createState() => _FormLaporanPageState();
}

class _FormLaporanPageState extends State<FormLaporanPage> {
  final _formKey = GlobalKey<FormState>();

  // Master data dari database via API
  List<Map<String, dynamic>> _kecamatanList = [];
  List<Map<String, dynamic>> _desaList = [];
  List<Map<String, dynamic>> _jalanList = [];
  List<Map<String, dynamic>> _kategoriList = [];

  // ID yang dipilih user
  int? _selectedIdKecamatan;
  int? _selectedIdDesa;
  int? _selectedIdJalan;
  int? _selectedIdKategori;

  bool _isLoadingMaster = true;
  bool _isLoadingDesa = false;
  bool _isLoadingJalan = false;

  // Koordinat GPS & Urgensi
  String _koordinat = '-8.178923, 113.653284 • Akurasi ± 2.4 meter';
  bool _isRefreshingGps = false;
  String _selectedUrgensi = 'Bahaya Tinggi';

  // Controller teks
  late final TextEditingController
  _jalanPatokanController; // Patokan spesifik (opsional)
  late final TextEditingController _deskripsiController;

  // Instance Service & Image Picker
  final _reportService = ReportService();
  final ImagePicker _picker = ImagePicker();

  // File foto asli yang dipilih dari kamera/galeri
  File? _selectedFile;
  bool _isSubmitting = false;

  // Daftar foto hasil pemilihan kamera atau galeri
  final List<ReportPhoto> _photos = [];

  @override
  void initState() {
    super.initState();
    _jalanPatokanController = TextEditingController();
    _deskripsiController = TextEditingController();
    _deskripsiController.addListener(() => setState(() {}));

    // Ambil data awal (Kecamatan & Kategori) dari Laravel
    _loadInitialData();
  }

  @override
  void dispose() {
    _jalanPatokanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingMaster = true);
    final k = await _reportService.getKecamatan();
    final kat = await _reportService.getKategori();

    if (!mounted) return;
    setState(() {
      _kecamatanList = k;
      _kategoriList = kat;
      if (_kategoriList.isNotEmpty) {
        _selectedIdKategori = _kategoriList.first['id_kategori'] as int;
      }
      _isLoadingMaster = false;
    });
  }

  // Dipanggil saat user memilih Kecamatan
  Future<void> _onKecamatanChanged(int? idKecamatan) async {
    if (idKecamatan == null) return;
    setState(() {
      _selectedIdKecamatan = idKecamatan;
      _selectedIdDesa = null;
      _selectedIdJalan = null;
      _desaList = [];
      _jalanList = [];
      _isLoadingDesa = true;
    });

    final desa = await _reportService.getDesa(idKecamatan);
    if (!mounted) return;
    setState(() {
      _desaList = desa;
      _isLoadingDesa = false;
    });
  }

  // Dipanggil saat user memilih Desa
  Future<void> _onDesaChanged(int? idDesa) async {
    if (idDesa == null) return;
    setState(() {
      _selectedIdDesa = idDesa;
      _selectedIdJalan = null;
      _jalanList = [];
      _isLoadingJalan = true;
    });

    final jalan = await _reportService.getJalan(idDesa);
    if (!mounted) return;
    setState(() {
      _jalanList = jalan;
      _isLoadingJalan = false;
    });
  }

  void _segarkanGps() {
    setState(() => _isRefreshingGps = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _isRefreshingGps = false;
        _koordinat =
            '-8.1789${100 + (now.millisecond % 800)}, 113.653${100 + (now.microsecond % 800)} • Akurasi ± 1.8 meter';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi GPS berhasil diperbarui!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF059669),
        ),
      );
    });
  }

  void _tambahFoto() {
    if (_photos.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 foto telah tercapai.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pilih Sumber Foto',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF7ED),
                    child: Icon(Icons.camera_alt, color: Color(0xFFEA580C)),
                  ),
                  title: const Text('Ambil dari Kamera'),
                  subtitle: const Text('Gunakan kamera langsung di lokasi'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _simpanFotoBaru('kamera');
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEFF6FF),
                    child: Icon(Icons.photo_library, color: Color(0xFF1E88E5)),
                  ),
                  title: const Text('Pilih dari Galeri'),
                  subtitle: const Text('Pilih gambar yang sudah ada'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _simpanFotoBaru('galeri');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _simpanFotoBaru(String sumber) async {
    final ImageSource source = (sumber == 'kamera')
        ? ImageSource.camera
        : ImageSource.gallery;

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      final fileName = pickedFile.name;

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')} WIB';

      setState(() {
        _selectedFile = file;
        _photos.clear();
        _photos.add(
          ReportPhoto(
            fileName: fileName,
            size: '$fileSizeInMB MB',
            tag: sumber == 'kamera' ? 'Foto Kamera' : 'Foto Galeri',
            time: timeStr,
          ),
        );
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Foto $fileName berhasil dipilih!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil foto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _hapusFoto(int index) {
    final removed = _photos[index];
    setState(() {
      _photos.removeAt(index);
      _selectedFile = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${removed.fileName} dihapus'),
        action: SnackBarAction(
          label: 'Batal',
          onPressed: () {
            setState(() => _photos.insert(index, removed));
          },
        ),
      ),
    );
  }

  Future<void> _submitLaporan() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIdJalan == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih ruas jalan terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedIdKategori == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon pilih kategori kerusakan!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon ambil foto bukti lapangan terlebih dahulu!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Gabungkan patokan detail jika ada
    final patokan = _jalanPatokanController.text.trim();
    final deskripsiLengkap = patokan.isNotEmpty
        ? '${_deskripsiController.text.trim()} (Patokan: $patokan)'
        : _deskripsiController.text.trim();

    // Kirim data asli ke Laravel (ID Jalan dan ID Kategori resmi)
    final result = await _reportService.createReport(
      idJalan: _selectedIdJalan!,
      idKategori: _selectedIdKategori!,
      tingkatBahaya: _selectedUrgensi,
      deskripsi: deskripsiLengkap,
      imageFile: _selectedFile!,
      latitude: -8.1789,
      longitude: 113.6532,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      // Ambil ulang list laporan agar halaman Beranda & Riwayat langsung terupdate
      await _reportService.fetchReports();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  result['message'] ?? 'Laporan berhasil terkirim ke server!',
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF059669),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Gagal mengirim laporan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 20),
              _buildLokasiSection(),
              const SizedBox(height: 20),
              _buildKategoriSection(),
              const SizedBox(height: 20),
              _buildTingkatBahayaSection(),
              const SizedBox(height: 20),
              _buildDokumentasiSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // === APP BAR ===
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF1E293B),
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[800]),
          const SizedBox(width: 8),
          Text(
            'SIGAP',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[900],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: Colors.black54),
          onPressed: () {},
        ),
        const Padding(
          padding: EdgeInsets.only(right: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ),
      ],
    );
  }

  // === JUDUL HALAMAN & SUBTITLE ===
  Widget _buildPageHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Formulir Pengaduan Kerusakan\nInfrastruktur Jalan',
              style: TextStyle(
                fontSize: compact ? 18 : 21,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Laporkan kondisi jalan berlubang, retak, atau ambles secara presisi untuk verifikasi tim teknis lapangan.',
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        );
      },
    );
  }

  // === SEKSI 1: LOKASI GEOSPASIAL INFRASTRUKTUR ===
  Widget _buildLokasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lokasi Geospasial Infrastruktur',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Dropdown Kecamatan & Desa
          Row(
            children: [
              // Kecamatan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRequiredLabel('Kecamatan'),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedIdKecamatan,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: const Text(
                        'Pilih Kecamatan',
                        style: TextStyle(fontSize: 12),
                      ),
                      items: _kecamatanList.map((k) {
                        return DropdownMenuItem<int>(
                          value: k['id_kecamatan'] as int,
                          child: Text(
                            k['nama_kecamatan'].toString(),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onKecamatanChanged,
                      validator: (v) => v == null ? 'Pilih kecamatan' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Desa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildRequiredLabel('Desa / Kelurahan'),
                        if (_isLoadingDesa) ...[
                          const SizedBox(width: 6),
                          const SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedIdDesa,
                      isExpanded: true,
                      decoration: _inputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      hint: Text(
                        _selectedIdKecamatan == null
                            ? 'Pilih Kec dulu'
                            : 'Pilih Desa',
                        style: const TextStyle(fontSize: 12),
                      ),
                      items: _desaList.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id_desa'] as int,
                          child: Text(
                            d['nama_desa'].toString(),
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedIdKecamatan == null
                          ? null
                          : _onDesaChanged,
                      validator: (v) => v == null ? 'Pilih desa' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Ruas Jalan (Dropdown dari Database!)
          Row(
            children: [
              _buildRequiredLabel('Ruas Jalan Terdaftar'),
              if (_isLoadingJalan) ...[
                const SizedBox(width: 6),
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedIdJalan,
            isExpanded: true,
            decoration: _inputDecoration(
              prefixIcon: const Icon(
                Icons.add_road_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            hint: Text(
              _selectedIdDesa == null
                  ? 'Pilih Desa terlebih dahulu'
                  : 'Pilih Ruas Jalan Resmi',
              style: const TextStyle(fontSize: 12),
            ),
            items: _jalanList.map((j) {
              return DropdownMenuItem<int>(
                value: j['id_jalan'] as int,
                child: Text(
                  j['nama_jalan'].toString(),
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _selectedIdDesa == null
                ? null
                : (v) => setState(() => _selectedIdJalan = v),
            validator: (v) => v == null ? 'Ruas jalan wajib dipilih' : null,
          ),
          const SizedBox(height: 14),

          // 3. Patokan Lokasi Detail (Opsional)
          const Text(
            'Patokan Lokasi Detail (Opsional)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _jalanPatokanController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: _inputDecoration(
              hintText: 'Contoh: Depan Indomaret / Depan Rumah No. 42',
              prefixIcon: const Icon(
                Icons.near_me_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Koordinat GPS Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Koordinat Lat/Long Terkunci',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _koordinat,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _isRefreshingGps ? null : _segarkanGps,
                  icon: _isRefreshingGps
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded, size: 14),
                  label: const Text(
                    'Segarkan GPS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2563EB),
                    side: const BorderSide(color: Color(0xFF93C5FD)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // === SEKSI 2: KATEGORI KERUSAKAN JALAN ===
  // === SEKSI 2: KATEGORI KERUSAKAN JALAN ===
  Widget _buildKategoriSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kategori Kerusakan Jalan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'WAJIB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_isLoadingMaster)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _kategoriList.map((kat) {
                final idKat = kat['id_kategori'] as int;
                final namaKat = kat['nama_kategori'].toString();
                final isSelected = _selectedIdKategori == idKat;

                return InkWell(
                  onTap: () => setState(() => _selectedIdKategori = idKat),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFFF7ED)
                          : const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      namaKat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFFEA580C)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // === SEKSI 3: TINGKAT BAHAYA & NARASI DETAIL ===
  Widget _buildTingkatBahayaSection() {
    final levels = [
      {
        'title': 'Rendah',
        'subtitle': 'Kerusakan ringan / tidak membahayakan',
        'dotColor': const Color(0xFF10B981),
      },
      {
        'title': 'Sedang',
        'subtitle': 'Mengganggu kelancaran lalu lintas',
        'dotColor': const Color(0xFFF59E0B),
      },
      {
        'title': 'Bahaya Tinggi',
        'subtitle': 'Rawan celaka fatal terutama bagi pesepeda motor',
        'dotColor': const Color(0xFFEF4444),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tingkat Bahaya & Narasi Detail',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estimasi potensi risiko terhadap pengguna jalan',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          _buildRequiredLabel('Tingkat Urgensi Kerusakan'),
          const SizedBox(height: 8),

          // Radio Cards
          ...levels.map((lvl) {
            final title = lvl['title'] as String;
            final subtitle = lvl['subtitle'] as String;
            final dotColor = lvl['dotColor'] as Color;
            final isSelected = _selectedUrgensi == title;
            final isHigh = title == 'Bahaya Tinggi';

            return InkWell(
              onTap: () => setState(() => _selectedUrgensi = title),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isHigh
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB))
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (isHigh
                              ? const Color(0xFFF87171)
                              : const Color(0xFFFBBF24))
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (isHigh
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFEA580C))
                              : const Color(0xFFCBD5E1),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isHigh
                                      ? const Color(0xFFEF4444)
                                      : const Color(0xFFEA580C),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected && isHigh
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (isHigh) ...[
                                const SizedBox(width: 4),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 14),

          // Deskripsi Detail
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildRequiredLabel('Deskripsi Detail Kondisi Lapangan'),
              Text(
                '${_deskripsiController.text.length}/500 karakter',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _deskripsiController,
            maxLines: 4,
            maxLength: 500,
            buildCounter:
                (
                  context, {
                  required currentLength,
                  required isFocused,
                  maxLength,
                }) => const SizedBox.shrink(),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Deskripsi kondisi lapangan wajib diisi';
              }
              return null;
            },
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: _inputDecoration(
              hintText: '...',
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }

  // === SEKSI 4: DOKUMENTASI BUKTI LAPANGAN ===
  Widget _buildDokumentasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        borderColor: const Color(0xFFF97316),
        borderWidth: 1.5,
        shadowColor: const Color(0xFFF97316).withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFFEA580C),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Dokumentasi Bukti Lapangan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'SEDANG DIISI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_photos.length} / 3 Foto',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFEA580C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Upload Area Box
          InkWell(
            onTap: _tambahFoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFDBA74), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFFEA580C),
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Klik untuk Ambil / Unggah Foto',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Gunakan kamera smartphone atau pilih foto dari galeri',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Maksimal 3 Foto • JPG, PNG • Maks. 5MB',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Foto terunggah ditampilkan setelah kotak unggah
          if (_photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Foto Terunggah Siap Diverifikasi (${_photos.length} Item)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF334155),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final entry in _photos.asMap().entries)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 72,
                        height: 72,
                        child: _selectedFile == null
                            ? Container(
                                color: const Color(0xFF1E293B),
                                child: const Icon(
                                  Icons.landscape_rounded,
                                  color: Colors.white70,
                                  size: 30,
                                ),
                              )
                            : Image.file(_selectedFile!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.value.fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  entry.value.tag,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.value.size,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Color(0xFF94A3B8),
                        size: 22,
                      ),
                      onPressed: () => _hapusFoto(entry.key),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  // === TOMBOL SUBMIT ===
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitLaporan,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEA580C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Submit Laporan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 18),
                ],
              ),
      ),
    );
  }

  // === HELPER STYLING ===
  BoxDecoration _cardDecoration({
    Color borderColor = const Color(0xFFE2E8F0),
    double borderWidth = 1.0,
    Color? shadowColor,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: [
        BoxShadow(
          color: shadowColor ?? Colors.black.withValues(alpha: 0.02),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  Widget _buildRequiredLabel(String text) {
    return RichText(
      text: TextSpan(
        text: '$text ',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
        children: const [
          TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    String? hintText,
    Widget? prefixIcon,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 12,
    ),
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      prefixIcon: prefixIcon,
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
    );
  }
}
