import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../laporan/widgets/road_damage_icon.dart';

class DetailTiketPage extends StatefulWidget {
  const DetailTiketPage({super.key, required this.report});

  final ReportModel report;

  @override
  State<DetailTiketPage> createState() => _DetailTiketPageState();
}

class _DetailTiketPageState extends State<DetailTiketPage> {
  final _reportService = ReportService();
  late ReportModel _report;
  bool _isRefreshing = false;

  static const _bulanIndo = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  static const _bulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  void initState() {
    super.initState();
    _report = widget.report;
    _refreshDetail();
  }

  Future<void> _refreshDetail() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    final updated = await _reportService.fetchReportDetail(_report.id);
    if (!mounted) return;
    setState(() {
      if (updated != null) {
        _report = updated;
      }
      _isRefreshing = false;
    });
  }

  String _formatTanggalLengkap(DateTime dt) {
    final local = dt.toLocal();
    final jam = local.hour.toString().padLeft(2, '0');
    final menit = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_bulanIndo[local.month - 1]} ${local.year}, $jam:$menit WIB';
  }

  String _formatTanggalSingkat(DateTime dt) {
    final local = dt.toLocal();
    final jam = local.hour.toString().padLeft(2, '0');
    final menit = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_bulanSingkat[local.month - 1]} ${local.year}, $jam:$menit WIB';
  }

  String _formatWaktuProgres(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    final jam = local.hour.toString().padLeft(2, '0');
    final menit = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${_bulanSingkat[local.month - 1]}, $jam:$menit';
  }

  void _copyText(String value, String label) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label disalin: $value'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0F172A),
      ),
    );
  }

  void _openFotoPreview() {
    if (_report.fotoUrl == null || _report.fotoUrl!.isEmpty) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: _report.fotoUrl!,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshDetail,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTicketHeader(),
              const SizedBox(height: 16),
              _buildDokumentasiCard(),
              const SizedBox(height: 16),
              _buildInfoLokasiCard(),
              const SizedBox(height: 16),
              _buildAlurPenangananCard(),
              const SizedBox(height: 16),
              _buildInfoTambahanCard(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 1,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: Color(0xFF0F172A),
          size: 19,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: const Row(
        children: [
          Text(
            'Riwayat Laporan',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '/',
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ),
          Text(
            'Detail Tiket',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ],
      ),
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTicketHeader() {
    final statusText = _report.status ?? 'Menunggu Validasi';
    final statusStyle = _statusBadgeStyle(statusText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 10,
          runSpacing: 8,
          children: [
            Text(
              _report.kodeTiket,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusStyle.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusStyle.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: statusStyle.dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: statusStyle.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Diajukan pada ${_formatTanggalLengkap(_report.createdAt)}',
          style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
        ),
      ],
    );
  }

  Widget _buildDokumentasiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 18,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Dokumentasi Bukti Lapangan',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              _buildUrgensiBadge(_report.tingkatBahaya),
            ],
          ),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _openFotoPreview,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                height: 220,
                color: const Color(0xFFF1F5F9),
                child: (_report.fotoUrl != null && _report.fotoUrl!.isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: _report.fotoUrl!,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            errorWidget: (context, url, error) => const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    size: 36,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    'Foto tidak dapat dimuat',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Perbesar',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Belum ada foto bukti lapangan',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoLokasiCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Lokasi & Kerusakan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetaField(
                  label: 'RUAS JALAN',
                  child: Text(
                    _report.jalanPatokan,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetaField(
                  label: 'WILAYAH ADMINISTRATIF',
                  child: Text(
                    '${_report.desa}, Kec. ${_report.kecamatan}',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildMetaField(
                  label: 'KATEGORI KERUSAKAN',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RoadDamageIcon(
                          categoryName: _report.kategori,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            _report.kategori,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildMetaField(
                  label: 'KOORDINAT GPS',
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Text(
                        _report.koordinat,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      InkWell(
                        onTap: () =>
                            _copyText(_report.koordinat, 'Koordinat GPS'),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 12,
                                color: Color(0xFF047857),
                              ),
                              SizedBox(width: 3),
                              Text(
                                'Salin',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetaField(
            label: 'DESKRIPSI ADUAN WARGA',
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Text(
                _report.deskripsi,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF334155),
                  height: 1.45,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }

  Widget _buildAlurPenangananCard() {
    final statusLower = (_report.status ?? '').toLowerCase();
    final isSelesai =
        statusLower.contains('selesai') ||
        statusLower.contains('bast') ||
        statusLower.contains('tuntas');
    final isDiproses =
        isSelesai ||
        statusLower.contains('proses') ||
        statusLower.contains('tindak') ||
        statusLower.contains('diterima') ||
        statusLower.contains('pupr') ||
        _report.progresList.isNotEmpty;
    final isTervalidasi = isDiproses || _report.verifiedAt != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 18,
                color: Color(0xFF2563EB),
              ),
              SizedBox(width: 8),
              Text(
                'Alur & Riwayat Penanganan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tahap 1: Laporan Berhasil Terkirim
          _buildTimelineStep(
            icon: Icons.check_rounded,
            iconBg: const Color(0xFF10B981),
            title: 'Laporan Berhasil Terkirim',
            subtitle:
                'Aduan masuk ke sistem SIGAP dan diteruskan ke Kecamatan ${_report.kecamatan}.',
            timestamp: _formatTanggalSingkat(_report.createdAt),
            showConnector: true,
          ),

          // Tahap 2: Validasi Lapangan Kecamatan
          _buildTimelineStep(
            icon: isTervalidasi
                ? Icons.check_rounded
                : Icons.hourglass_top_rounded,
            iconBg: isTervalidasi
                ? const Color(0xFF10B981)
                : const Color(0xFFF59E0B),
            title: 'Validasi Lapangan Kecamatan',
            subtitle: isTervalidasi
                ? 'Diverifikasi oleh: ${_report.verifikator ?? 'Admin Kecamatan'}'
                : 'Menunggu verifikasi lapangan oleh pihak Kecamatan.',
            timestamp: _report.verifiedAt != null
                ? _formatTanggalSingkat(_report.verifiedAt!)
                : null,
            extraContent:
                (_report.catatanVerifikasi != null &&
                    _report.catatanVerifikasi!.trim().isNotEmpty)
                ? Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CATATAN VERIFIKASI:',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF15803D),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '"${_report.catatanVerifikasi}"',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                : null,
            showConnector: true,
          ),

          // Tahap 3: Pengerjaan Tim Teknis PUPR
          _buildTimelineStep(
            icon: Icons.build_rounded,
            iconBg: isDiproses
                ? const Color(0xFF2563EB)
                : const Color(0xFFCBD5E1),
            title: 'Pengerjaan Tim Teknis PUPR',
            subtitle: isDiproses
                ? null
                : 'Tim teknis PUPR akan menindaklanjuti setelah validasi Kecamatan selesai.',
            extraContent: _report.progresList.isNotEmpty
                ? Column(
                    children: _report.progresList.map((item) {
                      final waktuStr = _formatWaktuProgres(item.waktu);
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.judul,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                                if (waktuStr.isNotEmpty)
                                  Text(
                                    waktuStr,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.catatan,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF334155),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                : (isDiproses
                      ? Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            isSelesai
                                ? 'Pekerjaan lapangan oleh Tim Teknis PUPR telah diselesaikan dan diterbitkan ke warga.'
                                : 'Laporan sedang dalam penanganan Tim Teknis PUPR (${_report.status ?? 'Diproses'}).',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E3A8A),
                              height: 1.4,
                            ),
                          ),
                        )
                      : null),
            showConnector: true,
          ),

          // Tahap 4: Perbaikan Selesai 100%
          _buildTimelineStep(
            icon: isSelesai ? Icons.check_rounded : Icons.flag_outlined,
            iconBg: isSelesai
                ? const Color(0xFF10B981)
                : const Color(0xFFCBD5E1),
            title: 'Perbaikan Selesai 100%',
            subtitle: isSelesai
                ? 'Ruas jalan telah selesai diperbaiki dan diverifikasi oleh pengawas UPT.'
                : 'Menunggu penyelesaian dan verifikasi akhir pengawas UPT.',
            showConnector: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required Color iconBg,
    required String title,
    String? subtitle,
    String? timestamp,
    Widget? extraContent,
    required bool showConnector,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 16),
              ),
              if (showConnector)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFE2E8F0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 18 : 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                  ],
                  ?extraContent,
                  if (timestamp != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      timestamp,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTambahanCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'INFORMASI TAMBAHAN',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Jika ada pembaruan kondisi mendesak terkait ruas jalan ini, Anda dapat menghubungi posko koordinasi penanganan jalan dengan menyebutkan nomor tiket:',
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _copyText(_report.kodeTiket, 'Nomor tiket'),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _report.kodeTiket,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.copy_rounded,
                    size: 15,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.phone_outlined, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'Call Center Jember: 112',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(Icons.email_outlined, size: 15, color: Color(0xFF64748B)),
              SizedBox(width: 8),
              Text(
                'sigap@jemberkab.go.id',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUrgensiBadge(String tingkatBahaya) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    final lower = tingkatBahaya.toLowerCase();
    if (lower.contains('tinggi') || lower.contains('berat')) {
      bgColor = const Color(0xFFFFF1F2);
      textColor = const Color(0xFFBE123C);
      borderColor = const Color(0xFFFECDD3);
    } else if (lower.contains('sedang')) {
      bgColor = const Color(0xFFFFFBEB);
      textColor = const Color(0xFFB45309);
      borderColor = const Color(0xFFFDE68A);
    } else {
      bgColor = const Color(0xFFECFDF5);
      textColor = const Color(0xFF047857);
      borderColor = const Color(0xFFA7F3D0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        tingkatBahaya.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  _StatusBadgeStyle _statusBadgeStyle(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('selesai') ||
        lower.contains('bast') ||
        lower.contains('tuntas')) {
      return const _StatusBadgeStyle(
        bg: Color(0xFFECFDF5),
        border: Color(0xFFA7F3D0),
        dot: Color(0xFF10B981),
        text: Color(0xFF047857),
      );
    }
    if (lower.contains('proses') ||
        lower.contains('tindak') ||
        lower.contains('diterima')) {
      return const _StatusBadgeStyle(
        bg: Color(0xFFEFF6FF),
        border: Color(0xFFBFDBFE),
        dot: Color(0xFF2563EB),
        text: Color(0xFF1D4ED8),
      );
    }
    return const _StatusBadgeStyle(
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
      dot: Color(0xFFF59E0B),
      text: Color(0xFFB45309),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.025),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}

class _StatusBadgeStyle {
  final Color bg;
  final Color border;
  final Color dot;
  final Color text;

  const _StatusBadgeStyle({
    required this.bg,
    required this.border,
    required this.dot,
    required this.text,
  });
}
