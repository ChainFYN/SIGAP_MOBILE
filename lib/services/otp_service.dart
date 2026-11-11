import 'dart:math';

enum OtpChannel {
  whatsapp('WhatsApp'),
  sms('SMS');

  final String label;
  const OtpChannel(this.label);
}

enum OtpStatus { success, wrong, expired, locked }

class OtpResult {
  final OtpStatus status;
  final int attemptsLeft;
  const OtpResult(this.status, {this.attemptsLeft = 0});
}

/// SIMULASI OTP (belum ada backend).
/// Nanti ganti isi [sendOtp] dan [verify] dengan pemanggilan API.
class OtpService {
  OtpService._();

  /// Tampilkan kode di SnackBar supaya bisa dites. Set false saat rilis.
  static const bool showDemoCode = true;

  static const int codeLength = 6;
  static const Duration validity = Duration(minutes: 5);
  static const Duration resendCooldown = Duration(seconds: 60);
  static const int maxAttempts = 5;

  static String? _code;
  static DateTime? _expiresAt;
  static DateTime? _resendAt;
  static int _attempts = 0;

  static bool get hasCode => _code != null;
  static bool get isLocked => _attempts >= maxAttempts;
  static bool get isExpired =>
      _expiresAt != null && !DateTime.now().isBefore(_expiresAt!);

  static Duration get remainingValidity => _left(_expiresAt);
  static Duration get remainingCooldown => _left(_resendAt);

  static Duration _left(DateTime? target) {
    if (target == null) return Duration.zero;
    final ms = target.difference(DateTime.now()).inMilliseconds;
    if (ms <= 0) return Duration.zero;
    return Duration(seconds: (ms / 1000).ceil());
  }

  /// TODO: ganti dengan request ke backend (kirim OTP ke [phone] via [channel]).
  static Future<String> sendOtp({
    required String phone,
    required OtpChannel channel,
  }) async {
    await Future.delayed(const Duration(milliseconds: 900));
    final rnd = Random.secure();
    _code = List.generate(codeLength, (_) => rnd.nextInt(10)).join();
    _attempts = 0;
    final now = DateTime.now();
    _expiresAt = now.add(validity);
    _resendAt = now.add(resendCooldown);
    return _code!;
  }

  /// TODO: ganti dengan request verifikasi ke backend.
  static Future<OtpResult> verify(String input) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (_code == null || isExpired) return const OtpResult(OtpStatus.expired);
    if (isLocked) return const OtpResult(OtpStatus.locked);

    if (input == _code) {
      reset();
      return const OtpResult(OtpStatus.success);
    }

    _attempts++;
    final left = maxAttempts - _attempts;
    return OtpResult(
      left <= 0 ? OtpStatus.locked : OtpStatus.wrong,
      attemptsLeft: left,
    );
  }

  static void reset() {
    _code = null;
    _expiresAt = null;
    _resendAt = null;
    _attempts = 0;
  }
}