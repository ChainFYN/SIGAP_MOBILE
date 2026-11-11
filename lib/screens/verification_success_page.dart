import 'package:flutter/material.dart';
import '../theme/sigap_colors.dart';
import 'home_page.dart';

class VerificationSuccessPage extends StatelessWidget {
  final String nama;

  const VerificationSuccessPage({super.key, required this.nama});

  @override
  Widget build(BuildContext context) {
    final trimmed = nama.trim();
    final first = trimmed.isEmpty ? '' : trimmed.split(RegExp(r'\s+')).first;

    return PopScope(
      canPop: false, // cegah balik ke halaman OTP
      child: Scaffold(
        backgroundColor: SigapColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: SigapColors.chipBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LANGKAH 3 DARI 3 • SELESAI',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: SigapColors.primaryDark,
                    ),
                  ),
                ),
                const Spacer(),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  builder: (context, v, child) =>
                      Transform.scale(scale: v, child: child),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                      color: SigapColors.successSoft,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 84,
                        height: 84,
                        decoration: const BoxDecoration(
                          color: SigapColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 52,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Verifikasi Berhasil!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: SigapColors.navy,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '${first.isEmpty ? 'Halo!' : 'Halo, $first!'} Nomor kamu sudah '
                  'terverifikasi dan akun SIGAP siap dipakai untuk melaporkan '
                  'kondisi jalan di sekitarmu.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: SigapColors.muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const HomePage()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SigapColors.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Masuk ke Dashboard',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}