import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme/sigap_colors.dart';

class NumericKeypad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onClear; // tahan lama tombol hapus
  final bool enabled;

  const NumericKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    this.onClear,
    this.enabled = true,
  });

  static const Map<String, String> _letters = {
    '1': '',
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
    '0': '',
  };

  Widget _digitKey(String d) {
    final letters = _letters[d] ?? '';
    return _Key(
      semanticLabel: 'Angka $d',
      onTap: enabled ? () => onDigit(d) : null,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            d,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: SigapColors.navy,
            ),
          ),
          if (letters.isNotEmpty)
            Text(
              letters,
              style: const TextStyle(
                fontSize: 8.5,
                letterSpacing: 1,
                color: SigapColors.hint,
              ),
            ),
        ],
      ),
    );
  }

  Widget _row(List<Widget> keys) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(child: keys[i]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: SigapColors.keypadTray,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _row([_digitKey('1'), _digitKey('2'), _digitKey('3')]),
          const SizedBox(height: 8),
          _row([_digitKey('4'), _digitKey('5'), _digitKey('6')]),
          const SizedBox(height: 8),
          _row([_digitKey('7'), _digitKey('8'), _digitKey('9')]),
          const SizedBox(height: 8),
          _row([
            const SizedBox(height: 52),
            _digitKey('0'),
            _Key(
              semanticLabel: 'Hapus',
              color: SigapColors.chipBlue,
              onTap: enabled ? onBackspace : null,
              onLongPress: enabled ? onClear : null,
              child: const Icon(
                Icons.backspace_outlined,
                color: SigapColors.navy,
                size: 22,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Color color;
  final String? semanticLabel;

  const _Key({
    required this.child,
    required this.onTap,
    this.onLongPress,
    this.color = Colors.white,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: color,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          onLongPress: onLongPress == null
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onLongPress!();
                },
          child: SizedBox(height: 52, child: Center(child: child)),
        ),
      ),
    );
  }
}