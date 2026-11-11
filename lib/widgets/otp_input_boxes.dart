import 'package:flutter/material.dart';
import '../theme/sigap_colors.dart';

class OtpInputBoxes extends StatelessWidget {
  final String value;
  final int length;
  final bool hasError;
  final bool isActive; // false saat loading / terkunci

  const OtpInputBoxes({
    super.key,
    required this.value,
    required this.length,
    this.hasError = false,
    this.isActive = true,
  });

  Widget _box(int i) {
    final filled = i < value.length;
    final active = isActive && i == value.length;

    final Color bg = hasError
        ? SigapColors.errorSoft
        : filled
            ? Colors.white
            : active
                ? SigapColors.chipBlue
                : SigapColors.boxEmpty;

    final Color borderColor = hasError
        ? SigapColors.error
        : active
            ? SigapColors.accent
            : filled
                ? SigapColors.border
                : Colors.transparent;

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 58,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: borderColor,
            width: (active || hasError) ? 2 : 1,
          ),
        ),
        child: filled
            ? Text(
                value[i],
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: SigapColors.navy,
                ),
              )
            : active
                ? const _BlinkingCursor()
                : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Kode OTP, ${value.length} dari $length digit terisi',
      child: Row(
        children: [
          for (int i = 0; i < length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _box(i),
          ],
        ],
      ),
    );
  }
}

class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _c,
      child: Container(
        width: 2,
        height: 26,
        decoration: BoxDecoration(
          color: SigapColors.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}