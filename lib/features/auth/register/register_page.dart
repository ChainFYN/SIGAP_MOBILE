import 'package:flutter/material.dart';
import '../otp/otp_verification_page.dart';

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
  final whatsappController = TextEditingController();
  final kecamatanController = TextEditingController();
  final desaController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;

  @override
  void dispose() {
    nikController.dispose();
    namaController.dispose();
    emailController.dispose();
    whatsappController.dispose();
    kecamatanController.dispose();
    desaController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationPage(
          phone: whatsappController.text.trim(),
          nama: namaController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            child: SizedBox(
              width: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Buat Akun',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Daftar untuk melaporkan kerusakan dan mengikuti progres laporan Anda',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('NIK'),
                          _buildTextField(
                            controller: nikController,
                            hint: 'Masukkan NIK Anda',
                            keyboard: TextInputType.number,
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'NIK wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Nama Lengkap'),
                          _buildTextField(
                            controller: namaController,
                            hint: 'Masukkan Nama Lengkap',
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Nama wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Email'),
                          _buildTextField(
                            controller: emailController,
                            hint: 'Masukkan Email Anda',
                            keyboard: TextInputType.emailAddress,
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Email wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Nomor WhatsApp'),
                          _buildTextField(
                            controller: whatsappController,
                            hint: 'Masukkan Nomor WhatsApp',
                            keyboard: TextInputType.phone,
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Nomor WhatsApp wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Kecamatan'),
                          _buildTextField(
                            controller: kecamatanController,
                            hint: 'Masukkan Kecamatan',
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Kecamatan wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Desa'),
                          _buildTextField(
                            controller: desaController,
                            hint: 'Masukkan Desa',
                            validator: (v) => (v ?? '').trim().isEmpty
                                ? 'Desa wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          _buildFieldLabel('Kata Sandi'),
                          TextFormField(
                            controller: passwordController,
                            obscureText: obscurePassword,
                            validator: (v) => (v ?? '').length < 6
                                ? 'Minimal 6 karakter'
                                : null,
                            decoration: InputDecoration(
                              hintText: 'Buat Kata Sandi',
                              prefixIcon: const Icon(Icons.lock_outline,
                                  color: Color(0xFF64748B)),
                              suffixIcon: IconButton(
                                onPressed: () => setState(
                                    () => obscurePassword = !obscurePassword),
                                icon: Icon(
                                  obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F5DCB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text(
                                'Daftar Akun',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                  ),
                                  child: const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}