import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../../../models/report_model.dart';
import '../../../services/report_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'detail_tiket_page.dart';

class RiwayatPage extends StatefulWidget {
  final String initialFilter;
  final VoidCallback? onProfileTap;

  const RiwayatPage({
    super.key,
    this.initialFilter = 'Semua',
    this.onProfileTap,
  });

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  final _reportService = ReportService();
  late String _selectedFilter;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    await _reportService.fetchReports();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF101B93), Color(0xFF1523BC)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Laporan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Laporan terdaftar atas nama Afan',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFFBFDBFE),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: widget.onProfileTap,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const TextField(
                    decoration: InputDecoration(
                      icon: Icon(Icons.search, color: Colors.grey),
                      hintText: 'Cari tiket LP-...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Filters
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('Semua'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Diproses'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Selesai'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Validasi'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF1E88E5)),
                  )
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ValueListenableBuilder<List<ReportModel>>(
                      valueListenable: ReportService.reportsNotifier,
                      builder: (context, reports, child) {
                        final filteredReports = reports.where((report) {
                          if (_selectedFilter == 'Semua') return true;
                          final status = (report.status ?? '').toLowerCase();
                          if (_selectedFilter == 'Diproses') {
                            return status.contains('proses') ||
                                status.contains('tindak') ||
                                status.contains('diterima');
                          }
                          if (_selectedFilter == 'Selesai') {
                            return status.contains('selesai') ||
                                status.contains('bast') ||
                                status.contains('tuntas');
                          }
                          if (_selectedFilter == 'Validasi') {
                            return status.contains('validasi') ||
                                status.contains('menunggu') ||
                                status.contains('verifikasi');
                          }
                          return true;
                        }).toList();

                        if (filteredReports.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  'Tidak ada laporan dengan filter $_selectedFilter.',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        return ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredReports.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final report = filteredReports[index];
                            return _buildReportCard(report);
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label.split(' ')[0];
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label.split(' ')[0];
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.blue[50],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.blue[800],
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  // Widget _buildDummyCard1() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'LP-2026-0842 • 24 SEP 2026',
  //               style: TextStyle(color: Colors.grey[600], fontSize: 12),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: Colors.orange[100],
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Container(
  //                     width: 6,
  //                     height: 6,
  //                     decoration: const BoxDecoration(
  //                       color: Colors.orange,
  //                       shape: BoxShape.circle,
  //                     ),
  //                   ),
  //                   const SizedBox(width: 4),
  //                   const Text(
  //                     'PUPR • Hotmix 75%',
  //                     style: TextStyle(
  //                       color: Colors.orange,
  //                       fontSize: 10,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           'Pengerjaan Hotmix Jalan Sukamaju',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(8),
  //               child: Container(
  //                 width: 80,
  //                 height: 80,
  //                 color: Colors.grey[300],
  //                 child: const Center(
  //                   child: Icon(Icons.image, color: Colors.grey),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       Icon(
  //                         Icons.location_on,
  //                         size: 14,
  //                         color: Colors.grey[600],
  //                       ),
  //                       const SizedBox(width: 4),
  //                       const Expanded(
  //                         child: Text(
  //                           'Jl. Sukamaju KM 4',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             fontSize: 13,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.only(left: 18.0),
  //                     child: Text(
  //                       'Depan SPBU Pertamina',
  //                       style: TextStyle(color: Colors.grey[600], fontSize: 12),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     'Jalan berlubang diameter 70cm, kedalaman 15cm berisiko bagi...',
  //                     style: TextStyle(color: Colors.grey[800], fontSize: 12),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         Container(
  //           padding: const EdgeInsets.all(12),
  //           decoration: BoxDecoration(
  //             color: Colors.grey[50],
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Column(
  //             children: [
  //               Row(
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: const [
  //                   Text('Progres Lapangan', style: TextStyle(fontSize: 12)),
  //                   Text(
  //                     '75% Selesai',
  //                     style: TextStyle(
  //                       fontSize: 12,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //               const SizedBox(height: 8),
  //               LinearProgressIndicator(
  //                 value: 0.75,
  //                 backgroundColor: Colors.grey[200],
  //                 color: Colors.orange,
  //                 minHeight: 6,
  //                 borderRadius: BorderRadius.circular(4),
  //               ),
  //             ],
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             onPressed: () {},
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: const Color(0xFF0F172A),
  //               padding: const EdgeInsets.symmetric(vertical: 12),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //             ),
  //             child: const Text(
  //               'Lacak Progres Realtime →',
  //               style: TextStyle(color: Colors.white),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ignore: unused_element
  // Widget _buildDummyCard2() {
  //   return Container(
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(16),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: 0.05),
  //           blurRadius: 10,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //           children: [
  //             Text(
  //               'LP-2026-0899 • HARI INI, 07:15 WIB',
  //               style: TextStyle(color: Colors.grey[600], fontSize: 12),
  //             ),
  //             Container(
  //               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  //               decoration: BoxDecoration(
  //                 color: Colors.blue[100],
  //                 borderRadius: BorderRadius.circular(12),
  //               ),
  //               child: const Text(
  //                 '⌛ Menunggu ACC Camat',
  //                 style: TextStyle(
  //                   color: Colors.blue,
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         const Text(
  //           'Saluran Drainase Ambles',
  //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  //         ),
  //         const SizedBox(height: 12),
  //         Row(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             ClipRRect(
  //               borderRadius: BorderRadius.circular(8),
  //               child: Container(
  //                 width: 80,
  //                 height: 80,
  //                 color: Colors.grey[300],
  //                 child: const Center(
  //                   child: Icon(Icons.image, color: Colors.grey),
  //                 ),
  //               ),
  //             ),
  //             const SizedBox(width: 12),
  //             Expanded(
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Row(
  //                     children: [
  //                       Icon(
  //                         Icons.location_on,
  //                         size: 14,
  //                         color: Colors.grey[600],
  //                       ),
  //                       const SizedBox(width: 4),
  //                       const Expanded(
  //                         child: Text(
  //                           'Jl. Flamboyan Gang 3',
  //                           style: TextStyle(
  //                             fontWeight: FontWeight.bold,
  //                             fontSize: 13,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                   Padding(
  //                     padding: const EdgeInsets.only(left: 18.0),
  //                     child: Text(
  //                       'RT 04 / RW 02',
  //                       style: TextStyle(color: Colors.grey[600], fontSize: 12),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 4),
  //                   Text(
  //                     'Saluran drainase ambles tersumbat memicu genangan air',
  //                     style: TextStyle(color: Colors.grey[800], fontSize: 12),
  //                     maxLines: 2,
  //                     overflow: TextOverflow.ellipsis,
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 16),
  //         SizedBox(
  //           width: double.infinity,
  //           child: ElevatedButton(
  //             onPressed: () {},
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.blue[50],
  //               elevation: 0,
  //               padding: const EdgeInsets.symmetric(vertical: 12),
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //             ),
  //             child: Text(
  //               'Lihat Tiket Pengaduan →',
  //               style: TextStyle(
  //                 color: Colors.blue[800],
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        tingkatBahaya.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReportCard(ReportModel report) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${report.kodeTiket} • ${dateFormat.format(report.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  report.status ?? 'Dilaporkan',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                report.kategori,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildUrgensiBadge(report.tingkatBahaya),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: (report.fotoUrl != null && report.fotoUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: report.fotoUrl!,
                          fit: BoxFit.cover,
                          // Optimasi ukuran render memori agar tidak berat di RAM
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            report.jalanPatokan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        '${report.desa}, ${report.kecamatan}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.deskripsi,
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DetailTiketPage(report: report),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Lihat Tiket Pengaduan →',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDummyCard3() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LP-2026-0791 • 15 SEP 2026',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8DF4D8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(
                      Icons.check_circle_outline,
                      size: 12,
                      color: Color(0xFF064E3B),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Tuntas Diperbaiki',
                      style: TextStyle(
                        color: Color(0xFF064E3B),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Perbaikan Aspal\nJembatan Ciluar',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.image, color: Colors.grey),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF064E3B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Selesai',
                        style: TextStyle(color: Colors.white, fontSize: 8),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_outlined,
                          size: 14,
                          color: Color(0xFF14B8A6),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'Jl. Raya Mayor Oking No. 88',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 18.0),
                      child: Text(
                        'Jembatan Kali Ciluar',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perbaikan aspal selesai total & telah diverifikasi oleh warga...',
                      style: TextStyle(color: Colors.grey[800], fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.shield_outlined,
                  size: 16,
                  color: Color(0xFF0F766E),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'BAST Ditandatangani • Nilai Kepuasan Warga: 4.9/5.0',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F766E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF022C22),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Lihat Berita Acara & Foto Selesai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.check, size: 16, color: Colors.white),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
