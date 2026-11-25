import 'dart:io';
import 'package:flutter/material.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import 'package:image_picker/image_picker.dart';

class FormLaporanPage extends StatefulWidget {
  const FormLaporanPage({super.key});

  @override
  State<FormLaporanPage> createState() => _FormLaporanPageState();
}

class _FormLaporanPageState extends State<FormLaporanPage> {
  final _formKey = GlobalKey<FormState>();

  // Data Master dari API
  List<Map<String, dynamic>> _kecamatanList = [];
  List<Map<String, dynamic>> _desaList = [];
  List<Map<String, dynamic>> _jalanList = [];
  List<Map<String, dynamic>> _kategoriList = [];

  // ID yang Sedang Dipilih User
  int? _selectedIdKecamatan;
  int? _selectedIdDesa;
  int? _selectedIdJalan;
  int? _selectedIdKategori;

  bool _isLoadingMaster = true;
  bool _isLoadingDesa = false;
  bool _isLoadingJalan = false;

  // Koordinat GPS
  String _koordinat = '-8.178923, 113.653284 • Akurasi ± 2.4 meter';
  bool _isRefreshingGps = false;

  // State untuk Tingkat Urgensi
  String _selectedUrgensi = 'Bahaya Tinggi';

  // Deskripsi
  late final TextEditingController _deskripsiController;
  late final TextEditingController _jalanController;

  // Instance Service & Image Picker
  final _reportService = ReportService();
  final ImagePicker _picker = ImagePicker();

  // File foto asli yang dipilih dari kamera/galeri
  File? _selectedFile;
  bool _isSubmitting = false;

  // Daftar Foto
  final List<ReportPhoto> _photos = [
    ReportPhoto(
      fileName: 'bukti_jalan_berlubang_1.jpg',
      size: '1.2 MB',
      tag: 'Tampak Dekat',
      time: '14:22:01 WIB',
    ),
    ReportPhoto(
      fileName: 'foto_kondisi_arus_lalu_lintas.jpg',
      size: '2.1 MB',
      tag: 'Tampak Lebar',
      time: '14:23:45 WIB',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _jalanController = TextEditingController();
    _deskripsiController = TextEditingController();
    _deskripsiController.addListener(() => setState(() {}));

    // Muat data awal dari API
    _loadInitialMasterData();
  }

  Future<void> _loadInitialMasterData() async {
    setState(() => _isLoadingMaster = true);

    final kecamatan = await _reportService.getKecamatan();
    final kategori = await _reportService.getKategori();

    if (!mounted) return;
    setState(() {
      _kecamatanList = kecamatan;
      _kategoriList = kategori;

      // Pilih kategori default jika tersedia
      if (_kategoriList.isNotEmpty) {
        _selectedIdKategori = _kategoriList.first['id_kategori'];
      }
      _isLoadingMaster = false;
    });
  }

  // Dipanggil ketika user memilih Kecamatan
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

  // Dipanggil ketika user memilih Desa
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

  @override
  void dispose() {
    _jalanController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  void _segarkanGps() {
    setState(() {
      _isRefreshingGps = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _isRefreshingGps = false;
          _koordinat =
              '-8.1789${(100 + (DateTime.now().millisecond % 800))}, 113.653${(100 + (DateTime.now().microsecond % 800))} • Akurasi ± 1.8 meter';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi GPS berhasil diperbarui!'),
            duration: Duration(seconds: 2),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
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
        imageQuality:
            80, // Kompres sedikit agar proses upload cepat & di bawah batas 5MB
      );

      if (pickedFile == null) return; // Dibatalkan pengguna

      final file = File(pickedFile.path);
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = (fileSizeInBytes / (1024 * 1024)).toStringAsFixed(1);
      final fileName = pickedFile.name;

      final now = DateTime.now();
      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')} WIB';

      setState(() {
        _selectedFile = file; // Simpan file fisik untuk dikirim ke backend
        _photos
            .clear(); // Backend Laravel saat ini memvalidasi 1 file utama ('foto')
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
            setState(() {
              _photos.insert(index, removed);
            });
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
    final patokan = _jalanController.text.trim();
    final deskripsiLengkap = patokan.isNotEmpty
        ? '${_deskripsiController.text.trim()} (Patokan: $patokan)'
        : _deskripsiController.text.trim();

    // Tingkat bahaya persis sesuai enum di Laravel ('Rendah', 'Sedang', 'Bahaya Tinggi')
    String urgensi = 'Bahaya Tinggi';
    if (_selectedUrgensi.contains('Rendah')) {
      urgensi = 'Rendah';
    } else if (_selectedUrgensi.contains('Sedang')) {
      urgensi = 'Sedang';
    }

    // Kirim form data asli ke Laravel
    final result = await _reportService.createReport(
      idJalan: _selectedIdJalan!,
      idKategori: _selectedIdKategori!,
      tingkatBahaya: urgensi,
      deskripsi: deskripsiLengkap,
      imageFile: _selectedFile!,
      latitude: -8.1789,
      longitude: 113.6532,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      // Ambil ulang list laporan dari Laravel agar Beranda & Riwayat otomatis sinkron
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
              _buildDokumentasiSection(),
              const SizedBox(height: 20),
              _buildLokasiSection(),
              const SizedBox(height: 20),
              _buildKategoriSection(),
              const SizedBox(height: 20),
              _buildTingkatBahayaSection(),
              const SizedBox(height: 24),
              _buildSubmitButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // === APP BAR SESUAI HALAMAN SEBELUMNYA ===
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Formulir Pengaduan Kerusakan\nInfrastruktur Jalan',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
            height: 1.25,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Laporkan kondisi jalan berlubang, retak, atau ambles secara presisi untuk verifikasi tim teknis lapangan.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
      ],
    );
  }

  // === SEKSI 1: DOKUMENTASI BUKTI LAPANGAN ===
  Widget _buildDokumentasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF97316), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
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

          // Upload Area Box (Dashed style container)
          InkWell(
            onTap: _tambahFoto,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFDBA74),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_photo_alternate_outlined,
                      color: Color(0xFFEA580C),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Klik untuk Ambil / Tarik Foto ke Sini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Mendukung kamera smartphone langsung atau galeri',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'Maksimal 3 Foto • Format: JPG, PNG (Max 5MB)',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Judul Foto Terunggah
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

          // List Foto Terunggah
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
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.landscape_rounded,
                            color: Colors.white70,
                            size: 26,
                          ),
                        ),
                        Positioned(
                          left: 4,
                          bottom: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              entry.value.size,
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
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
                              entry.value.time,
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

          const SizedBox(height: 12),

          // Panduan Validitas Laporan Warga
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1E36),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(
                      Icons.shield_outlined,
                      color: Color(0xFFFBBF24),
                      size: 18,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Panduan Validitas Laporan Warga',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFBBF24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildGuideItem(
                  'Pencahayaan Jelas : ',
                  'Hindari pengambilan gambar terlalu gelap atau saat hujan lebat.',
                ),
                const SizedBox(height: 6),
                _buildGuideItem(
                  'Patokan Fisik Permanen : ',
                  'Sertakan bangunan toko, plang nama jalan, atau tiang listrik.',
                ),
                const SizedBox(height: 6),
                _buildGuideItem(
                  'Objek Pembanding : ',
                  'Letakkan botol air mineral / sandal sebagai indikator kedalaman.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(String boldPrefix, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF10B981),
            size: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFFE2E8F0),
                height: 1.35,
              ),
              children: [
                TextSpan(
                  text: boldPrefix,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // === SEKSI 2: LOKASI GEOSPASIAL INFRASTRUKTUR ===
  Widget _buildLokasiSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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

          // Dropdown Row: Kecamatan & Desa
          Row(
            children: [
              // 1. Dropdown Kecamatan
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kecamatan *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: _selectedIdKecamatan,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onKecamatanChanged,
                      validator: (val) => val == null ? 'Wajib dipilih' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // 2. Dropdown Desa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Desa *',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
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
                      value: _selectedIdDesa,
                      isExpanded: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
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
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedIdKecamatan == null
                          ? null
                          : _onDesaChanged,
                      validator: (val) => val == null ? 'Wajib dipilih' : null,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Dropdown Ruas Jalan (Dari Database Laravel!)
          Row(
            children: [
              const Text(
                'Ruas Jalan Terdaftar *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
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
            value: _selectedIdJalan,
            isExpanded: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(
                Icons.add_road_rounded,
                color: Color(0xFF64748B),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
            hint: Text(
              _selectedIdDesa == null
                  ? 'Pilih Desa terlebih dahulu'
                  : 'Pilih Ruas Jalan',
              style: const TextStyle(fontSize: 12),
            ),
            items: _jalanList.map((j) {
              return DropdownMenuItem<int>(
                value: j['id_jalan'] as int,
                child: Text(
                  j['nama_jalan'].toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: _selectedIdDesa == null
                ? null
                : (val) => setState(() => _selectedIdJalan = val),
            validator: (val) => val == null ? 'Ruas jalan wajib dipilih' : null,
          ),

          const SizedBox(height: 14),

          // 4. Patokan Tambahan / Detail Titik Jalan
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
            controller: _jalanController,
            style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Contoh: Depan Indomaret / Depan Rumah No. 42',
              prefixIcon: const Icon(
                Icons.near_me_outlined,
                color: Color(0xFF64748B),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
            ),
          ),
          const SizedBox(height: 14),
          _buildGpsField(),
        ],
      ),
    );
  }

  Widget _buildGpsField() {
    return Container(
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  // === SEKSI 3: KATEGORI KERUSAKAN JALAN ===
  Widget _buildKategoriSection() {
    // Helper icon berdasarkan nama kategori
    IconData getCategoryIcon(String name) {
      final n = name.toLowerCase();
      if (n.contains('lubang')) return Icons.adjust_rounded;
      if (n.contains('gelombang')) return Icons.waves_rounded;
      if (n.contains('retak')) return Icons.grain_rounded;
      if (n.contains('ambles') || n.contains('longsor')) {
        return Icons.trending_down_rounded;
      }
      return Icons.category_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          getCategoryIcon(namaKat),
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          namaKat,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // === SEKSI 4: TINGKAT BAHAYA & NARASI DETAIL ===
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
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

          RichText(
            text: const TextSpan(
              text: 'Tingkat Urgensi Kerusakan ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
              children: [
                TextSpan(
                  text: '*',
                  style: TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Radio Cards
          ...levels.map((lvl) {
            final title = lvl['title'] as String;
            final subtitle = lvl['subtitle'] as String;
            final dotColor = lvl['dotColor'] as Color;
            final isSelected = _selectedUrgensi == title;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedUrgensi = title;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (title == 'Bahaya Tinggi'
                            ? const Color(0xFFFEF2F2)
                            : const Color(0xFFFFFBEB))
                      : const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (title == 'Bahaya Tinggi'
                              ? const Color(0xFFF87171)
                              : const Color(0xFFFBBF24))
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    // Radio button
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? (title == 'Bahaya Tinggi'
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
                                  color: title == 'Bahaya Tinggi'
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
                                  color: isSelected && title == 'Bahaya Tinggi'
                                      ? const Color(0xFFB91C1C)
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              if (title == 'Bahaya Tinggi') ...[
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
              RichText(
                text: const TextSpan(
                  text: 'Deskripsi Detail Kondisi Lapangan ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  children: [
                    TextSpan(
                      text: '*',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
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
            decoration: InputDecoration(
              hintText: '...',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
              contentPadding: const EdgeInsets.all(12),
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
            ),
          ),
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
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
}
