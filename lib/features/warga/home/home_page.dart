import 'package:flutter/material.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import '../laporan/form_laporan_page.dart';
import '../riwayat/riwayat_page.dart';
import '../../auth/login/login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    // Ambil laporan terbaru dari Laravel saat Beranda dibuka
    _reportService.fetchReports();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _getBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getBody() {
    switch (_selectedIndex) {
      case 0:
        return LayoutBuilder(
          builder: (context, constraints) {
            final mobileWidth = constraints.maxWidth;
            final maxContentWidth = mobileWidth > 520 ? 520.0 : mobileWidth;
            final horizontalPadding = mobileWidth < 340
                ? 10.0
                : mobileWidth < 390
                ? 12.0
                : 16.0;
            final statusColumns = 2;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: 14,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildGreetingSection(),
                        const SizedBox(height: 20),
                        _buildStatusHeader(),
                        const SizedBox(height: 14),
                        _buildStatusGrid(statusColumns),
                        const SizedBox(height: 18),
                        _buildWorkflowTimeline(),
                        ValueListenableBuilder<List<ReportModel>>(
                          valueListenable: ReportService.reportsNotifier,
                          builder: (context, reports, child) {
                            if (reports.isEmpty) return const SizedBox.shrink();
                            return Column(
                              children: [
                                const SizedBox(height: 18),
                                _buildRecentReports(),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      case 2:
        return const RiwayatPage();
      case 3:
        return const Center(child: Text('Halaman Profil'));
      default:
        return const SizedBox.shrink();
    }
  }

  // === Bagian Navigasi Bawah ===
  Widget _buildBottomNavigationBar() {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _buildNavItem(0, Icons.home_rounded, 'Beranda')),
              Expanded(
                child: _buildNavItem(1, Icons.add_rounded, 'Buat Lapor'),
              ),
              Expanded(
                child: _buildNavItem(2, Icons.history_rounded, 'Riwayat'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isActive = _selectedIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (index == 1) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FormLaporanPage()),
          );
          if (mounted) {
            setState(() {
              _selectedIndex = 0;
            });
          }
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Center(
        child: index == 1
            ? Container(
                width: 60,
                height: 60,
                margin: const EdgeInsets.only(top: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A8A),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, size: 30, color: Colors.white),
              )
            : SizedBox(
                height: 52,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: 24,
                      color: isActive
                          ? const Color(0xFF1E3A8A)
                          : Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF1E3A8A)
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0F172A),
      automaticallyImplyLeading: false,
      elevation: 0,
      toolbarHeight: 70,
      titleSpacing: 0,
      title: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 360;

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: compact ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'SIGAP',
                  style: TextStyle(
                    fontSize: compact ? 17 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Warga',
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    color: const Color(0xFFBFDBFE),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Row(
            children: [
              Text(
                'Warga Test\nPelapor Aktif',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showAccountPopup,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 17,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAccountPopup() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.blue[800],
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Afan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                const Text(
                  'warga@sigap.id',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Keluar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGreetingSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 360;
        final padding = compact ? 14.0 : 18.0;
        final titleSize = compact ? 26.0 : 30.0;
        final textSize = compact ? 11.5 : 12.0;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: const Color(0xFF1E3A8A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      'Selamat Datang, Ahmad Pratama',
                      style: TextStyle(
                        fontSize: titleSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Bersama Dinas PUBina Marga & PUPR Jember, pantau dan laporkan jalan rusak demi keselamatan bersama.',
                      style: TextStyle(
                        fontSize: textSize,
                        color: Colors.blue[100],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: compact ? 10 : 12),
              Container(
                width: compact ? 42 : 52,
                height: compact ? 42 : 52,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.people_alt_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            'STATUS ADUAN SAYA',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
              letterSpacing: 0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFDBEAFE),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'Aktif',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D4ED8),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusGrid(int crossAxisCount) {
    final totalDiajukan = ReportService.totalSubmitted;
    final totalMenunggu = ReportService.totalWaiting;

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _buildStatusCard(
          'Total Aduan',
          '$totalDiajukan',
          Icons.folder_rounded,
          const Color(0xFFE2E8F0),
          const Color(0xFF1E293B),
        ),
        _buildStatusCard(
          'Diproses',
          '$totalMenunggu',
          Icons.hourglass_top_rounded,
          const Color(0xFFDBEAFE),
          const Color(0xFF1D4ED8),
        ),
        _buildStatusCard(
          'Selesai',
          '2',
          Icons.check_circle_rounded,
          const Color(0xFFD1FAE5),
          const Color(0xFF059669),
        ),
        _buildStatusCard(
          'Validasi',
          '1',
          Icons.verified_rounded,
          const Color(0xFFFEF3C7),
          const Color(0xFFD97706),
        ),
      ],
    );
  }

  Widget _buildStatusCard(
    String title,
    String count,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 120;

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: compact ? 18 : 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                count,
                style: TextStyle(
                  fontSize: compact ? 22 : 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: compact ? 10.5 : 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkflowTimeline() {
    final steps = [
      {
        'label': 'Langkah 1',
        'title': 'Buat Laporan',
        'desc':
            'Sertakan foto kondisi jalan, alamat jalan, desa, dan koordinat GPS.',
        'icon': Icons.photo_camera_rounded,
        'color': const Color(0xFF0E2A6D),
      },
      {
        'label': 'Langkah 2',
        'title': 'Validasi Kecamatan',
        'desc': 'Kecamatan memverifikasi kebenaran dan tingkat urgensi aduan.',
        'icon': Icons.checklist_rounded,
        'color': const Color(0xFFF2A500),
      },
      {
        'label': 'Langkah 3',
        'title': 'Penanganan Dinas PUPR',
        'desc': 'UPT Bina Marga memberikan SPK dan menurunkan tim lapangan.',
        'icon': Icons.shield_rounded,
        'color': const Color(0xFF0F6DFF),
      },
      {
        'label': 'Langkah 4',
        'title': 'Selesai & FAST Terbit',
        'desc':
            'Perbaikan rampung 100% dan bukti fisik dipublikasikan di sistem.',
        'icon': Icons.check_rounded,
        'color': const Color(0xFF1FAE74),
      },
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: const BoxDecoration(color: Color(0xFFF2F4F7)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'ALUR KERJA PENANGANAN SIGAP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
                color: Color(0xFF6F86A6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...List.generate(steps.length, (index) {
            final step = steps[index];
            final isLast = index == steps.length - 1;

            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: step['color'] as Color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 60,
                          color: const Color(0xFFD8E0EA),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step['label'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step['title'] as String,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            step['desc'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF475569),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentReports() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pelacakan Terakhir',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'LP-2026-0007',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...ReportService.reports.map((report) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        report.kategori,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        report.tingkatBahaya,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${report.jalanPatokan}, ${report.desa}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timeline_rounded,
                      size: 16,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Progres Fisik Lapangan',
                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const Spacer(),
                    Text(
                      '75%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF3B82F6),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
