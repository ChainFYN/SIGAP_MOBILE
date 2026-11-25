import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../warga/home/home_page.dart';
import '../otp/otp_verification_page.dart';
import '../../../services/auth_service.dart';
import '../../../services/report_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _reportService = ReportService();

  final _nikController = TextEditingController();
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isLoadingDesa = false;

  // Master data
  List<Map<String, dynamic>> _kecamatanList = [];
  List<Map<String, dynamic>> _desaList = [];

  int? _selectedIdKecamatan;
  int? _selectedIdDesa;

  @override
  void initState() {
    super.initState();
    _loadKecamatan();
  }

  Future<void> _loadKecamatan() async {
    final data = await _reportService.getKecamatan();
    if (mounted) {
      setState(() => _kecamatanList = data);
    }
  }

  Future<void> _onKecamatanChanged(int? idKecamatan) async {
    if (idKecamatan == null) return;
    setState(() {
      _selectedIdKecamatan = idKecamatan;
      _selectedIdDesa = null;
      _desaList = [];
      _isLoadingDesa = true;
    });

    final data = await _reportService.getDesa(idKecamatan);
    if (mounted) {
      setState(() {
        _desaList = data;
        _isLoadingDesa = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIdDesa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan pilih Desa domisili Anda'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Format nomor WhatsApp: jika user mengisi tanpa 0 (misal: 812...), tambahkan 0 di depan
    String rawPhone = _whatsappController.text.trim();
    String phoneFormatted = rawPhone.startsWith('0') ? rawPhone : '0$rawPhone';

    final result = await _authService.register(
      nik: _nikController.text.trim(),
      namaLengkap: _namaController.text.trim(),
      email: _emailController.text.trim().toLowerCase(),
      telepon: phoneFormatted,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
      idDesa: _selectedIdDesa!,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registrasi berhasil!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      // Langsung arahkan ke halaman utama Warga
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Registrasi gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 32),
            child: SizedBox(
              width: 520,
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildFormCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
          ),
        ),
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0F172A),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: const Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.people_alt_rounded,
                color: Color(0xFF60A5FA),
                size: 38,
              ),
              Positioned(
                right: 17,
                top: 16,
                child: Icon(Icons.add, color: Color(0xFF22C55E), size: 20),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Registrasi Akun Warga',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 27,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 7),
        const Text(
          'Daftarkan akun pelapor Anda untuk berpartisipasi dalam perbaikan infrastruktur jalan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 26, 28, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildResponsiveRow(
              left: _buildTextFieldItem(
                label: 'NIK (Nomor Induk Kependudukan)',
                controller: _nikController,
                hint: '16 digit angka NIK',
                keyboard: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                ],
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'NIK wajib diisi';
                  if (value.length != 16) return 'NIK harus 16 digit';
                  return null;
                },
              ),
              right: _buildTextFieldItem(
                label: 'Alamat Email',
                controller: _emailController,
                hint: 'nama@gmail.com',
                keyboard: TextInputType.emailAddress,
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Email wajib diisi';
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Email tidak valid';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildResponsiveRow(
              left: _buildTextFieldItem(
                label: 'Nama Lengkap (sesuai KTP)',
                controller: _namaController,
                hint: 'Nama Lengkap Anda',
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              right: _buildTextFieldItem(
                label: 'Nomor WhatsApp / Telepon',
                controller: _whatsappController,
                hint: '81234567890',
                keyboard: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(15),
                ],
                prefixText: '+62  ',
                validator: (v) {
                  final value = (v ?? '').trim();
                  if (value.isEmpty) return 'Nomor wajib diisi';
                  if (value.length < 9) return 'Nomor terlalu pendek';
                  return null;
                },
              ),
            ),
            const SizedBox(height: 14),
            _buildResponsiveRow(
              left: _buildDropdownItem(
                label: 'Kecamatan Domisili',
                hint: 'Pilih Kecamatan',
                value: _selectedKecamatan,
                items: _kecamatanList,
                onChanged: (value) => setState(() => _selectedKecamatan = value),
              ),
              right: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Kelurahan / Desa *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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
                    initialValue: _selectedIdDesa,
                    isExpanded: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                        ),
                      );
                    }).toList(),
                    onChanged: _selectedIdKecamatan == null
                        ? null
                        : (v) => setState(() => _selectedIdDesa = v),
                    validator: (v) => v == null ? 'Wajib dipilih' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            _buildResponsiveRow(
              left: _buildPasswordItem(
                label: 'Kata Sandi',
                controller: _passwordController,
                hint: '8 - 12 karakter',
                obscure: _obscurePassword,
                onToggle: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                validator: (v) {
                  final value = v ?? '';
                  if (value.isEmpty) return 'Kata sandi wajib diisi';
                  if (value.length < 8) return 'Minimal 8 karakter';
                  if (value.length > 12) return 'Maksimal 12 karakter';
                  return null;
                },
              ),
              right: _buildPasswordItem(
                label: 'Ulangi Kata Sandi',
                controller: _confirmPasswordController,
                hint: 'Ketik ulang kata sandi',
                obscure: _obscureConfirmPassword,
                onToggle: () => setState(
                  () => _obscureConfirmPassword = !_obscureConfirmPassword,
                ),
                validator: (v) {
                  if ((v ?? '').isEmpty) return 'Konfirmasi kata sandi wajib diisi';
                  if (v != _passwordController.text) {
                    return 'Kata sandi tidak sama';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 22),
            _buildSubmitButton(),
            const SizedBox(height: 16),
            _buildLoginRedirect(),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF111827),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add_alt_1, color: Color(0xFF22C55E), size: 20),
            SizedBox(width: 8),
            Text(
              'Daftarkan Akun Pelapor Warga',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text(
          'Sudah memiliki akun? ',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Masuk ke sini',
            style: TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveRow({required Widget left, required Widget right}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 430) {
          return Column(children: [left, const SizedBox(height: 14), right]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            const SizedBox(width: 14),
            Expanded(child: right),
          ],
        );
      },
    );
  }

  Widget _buildLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextFieldItem({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: _inputDecoration(hint).copyWith(
            prefixText: prefixText,
            prefixStyle: const TextStyle(
              color: Color(0xFF334155),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordItem({
    required String label,
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          validator: validator,
          decoration: _inputDecoration(hint).copyWith(
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownItem({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 7),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          validator: (v) => v == null ? 'Wajib dipilih' : null,
          decoration: _inputDecoration(hint),
          hint: Text(
            hint,
            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE11D48)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
    );
  }
}
