import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_input.dart';
import '../widgets/section_title.dart';
import '../widgets/custom_dropdown.dart';
import '../widgets/step_progress.dart';
import 'login_page.dart';
import 'otp_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final nikController = TextEditingController();
  final namaController = TextEditingController();
  final emailController = TextEditingController();
  final noHpController = TextEditingController();
  final passwordController = TextEditingController();
  final ulangPasswordController = TextEditingController();

  // Daftar kecamatan beserta kelurahan/desa di dalamnya
  static const Map<String, List<String>> _wilayah = {
    'Kaliwates': [
      'Kaliwates',
      'Jember Kidul',
      'Tegal Besar',
      'Sempusari',
      'Mangli',
      'Kebon Agung',
      'Kepatihan',
    ],
    'Sumbersari': [
      'Sumbersari',
      'Kebonsari',
      'Karangrejo',
      'Wirolegi',
      'Tegalgede',
      'Antirogo',
      'Kranjingan',
    ],
    'Patrang': [
      'Patrang',
      'Jemberlor',
      'Gebang',
      'Banjarsengon',
      'Baratan',
      'Bintoro',
      'Slawu',
      'Jumerto',
    ],
  };

  String? selectedKecamatan;
  String? selectedDesa;

  bool obscurePassword = true;
  bool obscureUlangPassword = true;

  // Kelurahan/desa hanya tersedia setelah kecamatan dipilih
  List<String> get _daftarDesa =>
      selectedKecamatan == null ? const [] : _wilayah[selectedKecamatan]!;

  @override
  void dispose() {
    nikController.dispose();
    namaController.dispose();
    emailController.dispose();
    noHpController.dispose();
    passwordController.dispose();
    ulangPasswordController.dispose();
    super.dispose();
  }

  // ---------- VALIDATOR (disamakan dengan versi Laravel) ----------

  String? _validasiNik(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'NIK wajib diisi';
    if (!RegExp(r'^\d{16}$').hasMatch(v)) return 'NIK harus 16 digit angka';
    return null;
  }

  String? _validasiNama(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nama lengkap wajib diisi';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(v)) {
      return 'Nama hanya boleh huruf dan spasi';
    }
    return null;
  }

  String? _validasiEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Alamat email wajib diisi';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)) {
      return 'Format email tidak valid';
    }
    return null;
  }

  String? _validasiNoHp(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Nomor WhatsApp wajib diisi';
    if (v.startsWith('0')) return 'Tanpa angka 0 di depan';
    if (!RegExp(r'^\d{11,12}$').hasMatch(v)) return 'Harus 11-12 digit angka';
    return null;
  }

  String? _validasiPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Kata sandi wajib diisi';
    if (v.length < 8 || v.length > 12) return 'Kata sandi 8 - 12 karakter';
    return null;
  }

  String? _validasiUlangPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Ulangi kata sandi wajib diisi';
    if (v != passwordController.text) return 'Kata sandi tidak sama';
    return null;
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    // Pakai push (bukan pushAndRemoveUntil) supaya kalau user batal,
    // dia balik ke form dengan data yang masih terisi.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          phone: noHpController.text.trim(),
          nama: namaController.text.trim(),
        ),
      ),
    );
  }

  Widget _passwordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLength: 12,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'SIGAP',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1565C0),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Registrasi Akun Warga',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Daftarkan akun pelapor Anda untuk berpartisipasi dalam '
                  'perbaikan infrastruktur jalan.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // PROGRESS STEP (Daftar - Verifikasi - Selesai)
                const StepProgress(currentStep: 1),

                const SizedBox(height: 28),

                // SECTION: DATA DIRI
                const SectionTitle(
                  icon: Icons.person_outline,
                  title: 'Data Diri',
                ),
                const SizedBox(height: 12),

                CustomInput(
                  controller: nikController,
                  label: 'NIK (Nomor Induk Kependudukan)',
                  hint: '16 digit angka NIK',
                  icon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  maxLength: 16,
                  helperText: 'Hanya angka, harus 16 digit sesuai KTP.',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validasiNik,
                ),
                const SizedBox(height: 14),

                CustomInput(
                  controller: namaController,
                  label: 'Nama Lengkap (sesuai KTP)',
                  hint: 'Nama Lengkap Anda',
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  helperText: 'Hanya huruf dan spasi.',
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                  validator: _validasiNama,
                ),
                const SizedBox(height: 14),

                CustomInput(
                  controller: emailController,
                  label: 'Alamat Email',
                  hint: 'nama@email.com',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _validasiEmail,
                ),
                const SizedBox(height: 14),

                CustomInput(
                  controller: noHpController,
                  label: 'Nomor WhatsApp / Telepon',
                  hint: '81234567890',
                  prefixText: '+62  ',
                  keyboardType: TextInputType.phone,
                  maxLength: 12,
                  helperText: '11-12 digit angka (tanpa 0 di depan).',
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: _validasiNoHp,
                ),

                const SizedBox(height: 24),

                // SECTION: DATA DOMISILI
                const SectionTitle(
                  icon: Icons.location_on_outlined,
                  title: 'Data Domisili',
                ),
                const SizedBox(height: 12),

                // Kecamatan domisili (wajib diisi lebih dulu)
                CustomDropdown(
                  title: 'Kecamatan Domisili',
                  hint: 'Pilih Kecamatan',
                  items: _wilayah.keys.toList(),
                  value: selectedKecamatan,
                  validator: (val) =>
                      val == null ? 'Kecamatan domisili wajib dipilih' : null,
                  onChanged: (val) {
                    setState(() {
                      selectedKecamatan = val;
                      selectedDesa = null; // reset desa saat kecamatan berubah
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Kelurahan/Desa: nonaktif sampai kecamatan dipilih.
                // ValueKey memaksa dropdown dibangun ulang saat kecamatan
                // berganti, supaya pilihan desa sebelumnya benar-benar hilang.
                CustomDropdown(
                  key: ValueKey('desa-${selectedKecamatan ?? 'kosong'}'),
                  title: 'Kelurahan / Desa',
                  hint: selectedKecamatan == null
                      ? 'Pilih Kecamatan terlebih dahulu'
                      : 'Pilih Kelurahan / Desa',
                  items: _daftarDesa,
                  value: selectedDesa,
                  validator: (val) =>
                      val == null ? 'Kelurahan / Desa wajib dipilih' : null,
                  onChanged: selectedKecamatan == null
                      ? null
                      : (val) {
                          setState(() {
                            selectedDesa = val;
                          });
                        },
                ),

                const SizedBox(height: 24),

                // SECTION: KEAMANAN
                const SectionTitle(
                  icon: Icons.security_outlined,
                  title: 'Keamanan',
                ),
                const SizedBox(height: 12),

                _passwordField(
                  controller: passwordController,
                  label: 'Kata Sandi',
                  hint: '8 - 12 karakter',
                  obscure: obscurePassword,
                  onToggle: () =>
                      setState(() => obscurePassword = !obscurePassword),
                  validator: _validasiPassword,
                ),
                const SizedBox(height: 14),

                _passwordField(
                  controller: ulangPasswordController,
                  label: 'Ulangi Kata Sandi',
                  hint: 'Ketik ulang kata sandi',
                  obscure: obscureUlangPassword,
                  onToggle: () => setState(
                      () => obscureUlangPassword = !obscureUlangPassword),
                  validator: _validasiUlangPassword,
                ),

                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pastikan data yang kamu masukkan sudah benar. '
                          'Data akan digunakan untuk proses verifikasi akun.',
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _submitForm,
                    icon: const Icon(Icons.how_to_reg_outlined),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E88E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    label: const Text(
                      'Daftarkan Akun Pelapor Warga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text(
                      'Sudah punya akun? Sign In',
                      style: TextStyle(
                        color: Color(0xFF1E88E5),
                        fontWeight: FontWeight.w600,
                      ),
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