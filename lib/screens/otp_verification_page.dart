import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/otp_service.dart';
import '../theme/sigap_colors.dart';
import '../widgets/numeric_keypad.dart';
import '../widgets/otp_input_boxes.dart';
import 'verification_success_page.dart';

class OtpVerificationPage extends StatefulWidget {
  final String phone; // tanpa 0 di depan, contoh: 81234567890
  final String nama;

  const OtpVerificationPage({
    super.key,
    required this.phone,
    required this.nama,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage>
    with SingleTickerProviderStateMixin {
  String _code = '';
  bool _sending = true; // kirim OTP pertama dimulai saat halaman dibuka
  bool _verifying = false;
  bool _hasError = false;
  String? _errorText;
  OtpChannel _channel = OtpChannel.whatsapp;

  late final AnimationController _shake;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    // Refresh tampilan tiap detik untuk countdown
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _send(OtpChannel.whatsapp, first: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _shake.dispose();
    super.dispose();
  }

  // ---------- HELPER ----------

  String _maskedPhone() {
    final p = widget.phone;
    if (p.length < 7) return '+62 $p';
    return '+62 ${p.substring(0, 3)}-****-${p.substring(p.length - 4)}';
  }

  String _mmss(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------- AKSI ----------

  Future<void> _send(OtpChannel channel, {bool first = false}) async {
    if (!first) {
      setState(() {
        _sending = true;
        _channel = channel;
        _code = '';
        _errorText = null;
        _hasError = false;
      });
    }

    final code = await OtpService.sendOtp(phone: widget.phone, channel: channel);
    if (!mounted) return;

    setState(() {
      _sending = false;
      _channel = channel;
    });
    _notifySent(code, channel, first);
  }

  void _notifySent(String code, OtpChannel channel, bool first) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    if (OtpService.showDemoCode) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: SigapColors.navy,
          duration: const Duration(seconds: 12),
          content: Text('Mode demo • kode OTP kamu: $code'),
          action: SnackBarAction(
            label: 'ISI OTOMATIS',
            textColor: SigapColors.accent,
            onPressed: () {
              setState(() => _code = code);
              _submit();
            },
          ),
        ),
      );
    } else if (!first) {
      messenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Kode baru dikirim via ${channel.label}'),
        ),
      );
    }
  }

  void _addDigit(String d) {
    if (_verifying || _sending || _code.length >= OtpService.codeLength) return;
    setState(() {
      _code += d;
      _errorText = null;
      _hasError = false;
    });
    if (_code.length == OtpService.codeLength) {
      // jeda singkat supaya digit terakhir sempat terlihat
      Future.delayed(const Duration(milliseconds: 180), () {
        if (mounted) _submit();
      });
    }
  }

  void _backspace() {
    if (_verifying || _code.isEmpty) return;
    setState(() {
      _code = _code.substring(0, _code.length - 1);
      _errorText = null;
      _hasError = false;
    });
  }

  void _clear() {
    if (_verifying || _code.isEmpty) return;
    setState(() {
      _code = '';
      _errorText = null;
      _hasError = false;
    });
  }

  Future<void> _submit() async {
    if (_verifying || _sending || _code.length != OtpService.codeLength) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _verifying = true);

    final result = await OtpService.verify(_code);
    if (!mounted) return;

    switch (result.status) {
      case OtpStatus.success:
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerificationSuccessPage(nama: widget.nama),
          ),
        );
        break;
      case OtpStatus.wrong:
        await _showError(
          'Kode salah. Sisa percobaan: ${result.attemptsLeft}x',
        );
        break;
      case OtpStatus.expired:
        await _showError('Kode sudah kedaluwarsa. Kirim ulang kode baru.');
        break;
      case OtpStatus.locked:
        await _showError(
          'Terlalu banyak percobaan salah. Kirim ulang kode baru.',
        );
        break;
    }
  }

  Future<void> _showError(String message) async {
    HapticFeedback.heavyImpact();
    setState(() {
      _verifying = false;
      _hasError = true;
      _errorText = message;
    });
    await _shake.forward(from: 0);
    if (!mounted) return;
    setState(() {
      _hasError = false;
      _code = ''; // kosongkan supaya user bisa langsung ngetik ulang
    });
  }

  Future<void> _confirmCancel() async {
    if (_verifying) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Batalkan verifikasi?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Akunmu belum aktif sebelum nomor terverifikasi. '
          'Data pendaftaran masih tersimpan di formulir, jadi kamu bisa '
          'lanjut lagi kapan saja.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Lanjut verifikasi'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Ya, kembali',
              style: TextStyle(color: SigapColors.error),
            ),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      OtpService.reset();
      Navigator.pop(context);
    }
  }

  // Keyboard fisik (web/desktop/emulator)
  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final ch = event.character;
    if (ch != null && RegExp(r'^\d$').hasMatch(ch)) {
      _addDigit(ch);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      _submit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---------- UI ----------

  @override
  Widget build(BuildContext context) {
    final cooldown = OtpService.remainingCooldown;
    final validity = OtpService.remainingValidity;
    final expired = OtpService.hasCode && OtpService.isExpired;
    final locked = OtpService.isLocked;
    final canType = !_sending && !_verifying && !expired && !locked;
    final canResend = !_sending && !_verifying && cooldown == Duration.zero;
    final isComplete = _code.length == OtpService.codeLength;

    String statusLine;
    if (_sending) {
      statusLine = 'Sedang mengirim kode...';
    } else if (cooldown > Duration.zero) {
      statusLine = 'Kirim ulang kode dalam ${_mmss(cooldown)}';
    } else {
      statusLine = 'Belum menerima kode? Kirim ulang sekarang';
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Focus(
        autofocus: true,
        onKeyEvent: _onKey,
        child: Scaffold(
          backgroundColor: SigapColors.background,
          body: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: Column(
                      children: [
                        _stepChip(),
                        const SizedBox(height: 22),
                        _buildShield(),
                        const SizedBox(height: 18),
                        const Text(
                          'Masukkan Kode OTP',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: SigapColors.navy,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sending
                              ? 'Mengirim kode verifikasi...'
                              : 'Kami telah mengirimkan ${OtpService.codeLength} digit '
                                  'kode verifikasi ke nomor ${_channel.label} kamu',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: SigapColors.muted,
                            fontSize: 13.5,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _phoneChip(),
                        const SizedBox(height: 14),
                        Text(
                          statusLine,
                          style: const TextStyle(
                            color: SigapColors.accentText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // KOTAK OTP (bergetar saat salah)
                        AnimatedBuilder(
                          animation: _shake,
                          builder: (context, child) {
                            final t = _shake.value;
                            final dx = math.sin(t * math.pi * 6) * 10 * (1 - t);
                            return Transform.translate(
                              offset: Offset(dx, 0),
                              child: child,
                            );
                          },
                          child: OtpInputBoxes(
                            value: _code,
                            length: OtpService.codeLength,
                            hasError: _hasError,
                            isActive: canType,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _helperLine(),
                        const SizedBox(height: 10),
                        if (!_sending) _expiryChip(expired, validity),
                        const SizedBox(height: 6),

                        // KIRIM ULANG
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _resendLink(
                              'Kirim via WhatsApp',
                              OtpChannel.whatsapp,
                              canResend,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(color: SigapColors.hint),
                              ),
                            ),
                            _resendLink(
                              'Kirim via SMS',
                              OtpChannel.sms,
                              canResend,
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // TOMBOL VERIFIKASI
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: (isComplete && canType) ? _submit : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SigapColors.accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: SigapColors.accentSoft,
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _verifying
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Verifikasi & Lanjutkan',
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
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _verifying ? null : _confirmCancel,
                          child: const Text(
                            'Batal dan Kembali',
                            style: TextStyle(
                              color: SigapColors.navy,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        NumericKeypad(
                          enabled: canType,
                          onDigit: _addDigit,
                          onBackspace: _backspace,
                          onClear: _clear,
                        ),
                        const SizedBox(height: 18),
                        _securityCard(),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: _confirmCancel,
            icon: const Icon(Icons.arrow_back, color: SigapColors.navy),
          ),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: SigapColors.navy,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(Icons.shield, color: SigapColors.accent, size: 20),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SIGAP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: SigapColors.accentText,
                ),
              ),
              Text(
                'Verifikasi OTP',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: SigapColors.navy,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: SigapColors.chipBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'LANGKAH 2 DARI 3 • VERIFIKASI KEAMANAN',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
          color: SigapColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildShield() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: const BoxDecoration(
            color: SigapColors.navy,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.verified_user_rounded,
            color: SigapColors.accent,
            size: 40,
          ),
        ),
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: SigapColors.accent,
              shape: BoxShape.circle,
              border: Border.all(color: SigapColors.background, width: 3),
            ),
            child: Icon(
              _channel == OtpChannel.whatsapp
                  ? Icons.chat_bubble
                  : Icons.sms,
              color: Colors.white,
              size: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SigapColors.boxEmpty,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SigapColors.chipBlue),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.phone_iphone, size: 16, color: SigapColors.primary),
          const SizedBox(width: 8),
          Text(
            _maskedPhone(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: SigapColors.navy,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _helperLine() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _errorText != null
          ? Row(
              key: ValueKey(_errorText),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 16, color: SigapColors.error),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _errorText!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: SigapColors.error,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          : const Row(
              key: ValueKey('hint'),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 16, color: SigapColors.muted),
                SizedBox(width: 6),
                Text(
                  'Pastikan kode hanya terdiri dari angka',
                  style: TextStyle(color: SigapColors.muted, fontSize: 12.5),
                ),
              ],
            ),
    );
  }

  Widget _expiryChip(bool expired, Duration validity) {
    final color = expired ? SigapColors.error : SigapColors.primaryDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: expired ? SigapColors.errorSoft : SigapColors.chipBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            expired ? Icons.timer_off_outlined : Icons.timer_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            expired
                ? 'Kode kedaluwarsa, kirim ulang kode baru'
                : 'Kode berlaku selama ${_mmss(validity)}',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _resendLink(String text, OtpChannel channel, bool enabled) {
    return TextButton(
      onPressed: enabled ? () => _send(channel) : null,
      style: TextButton.styleFrom(
        foregroundColor: SigapColors.primary,
        disabledForegroundColor: SigapColors.hint,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _securityCard() {
    Widget item(String text) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 1),
                child: Icon(Icons.check_circle,
                    size: 15, color: SigapColors.success),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.35,
                    color: SigapColors.muted,
                  ),
                ),
              ),
            ],
          ),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SigapColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lock_outline, size: 16, color: SigapColors.navy),
              SizedBox(width: 8),
              Text(
                'Keamanan Akses Tingkat Tinggi',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: SigapColors.navy,
                ),
              ),
            ],
          ),
          item('Dilindungi enkripsi TLS 1.3'),
          item('Aktivitas akun tercatat (audit trail)'),
          item('Kode berlaku 5 menit dan hanya sekali pakai'),
          item('Jangan bagikan kode ke siapa pun, termasuk petugas'),
        ],
      ),
    );
  }
}