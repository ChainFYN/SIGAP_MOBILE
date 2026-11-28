import 'package:flutter/material.dart';

enum RoadDamageType { berlubang, bergelombang, retak, amblesLongsor, lainnya }

/// Simplified vector road-perspective icon matching the 5 road damage categories.
class RoadDamageIcon extends StatelessWidget {
  const RoadDamageIcon({
    super.key,
    required this.categoryName,
    this.size = 24,
    this.isSelected = false,  
  });

  final String categoryName;
  final double size;
  final bool isSelected;

  static RoadDamageType resolveType(String nama) {
    final lower = nama.toLowerCase();
    if (lower.contains('lubang')) return RoadDamageType.berlubang;
    if (lower.contains('gelombang')) return RoadDamageType.bergelombang;
    if (lower.contains('retak')) return RoadDamageType.retak;
    if (lower.contains('ambles') || lower.contains('longsor')) {
      return RoadDamageType.amblesLongsor;
    }
    return RoadDamageType.lainnya;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RoadDamageIconPainter(
          type: resolveType(categoryName),
          isSelected: isSelected,
        ),
      ),
    );
  }
}

class _RoadDamageIconPainter extends CustomPainter {
  const _RoadDamageIconPainter({required this.type, required this.isSelected});

  final RoadDamageType type;
  final bool isSelected;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final strokeColor = isSelected
        ? const Color(0xFF9A3412)
        : const Color(0xFF334155);
    final roadFill = isSelected
        ? const Color(0xFFFFEDD5)
        : const Color(0xFFE2E8F0);
    final curbColor = isSelected
        ? const Color(0xFFEA580C)
        : const Color(0xFF64748B);

    final outlinePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.065
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dashPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.06
      ..strokeCap = StrokeCap.round;

    if (type == RoadDamageType.amblesLongsor) {
      _drawAmblesLongsor(
        canvas,
        w,
        h,
        roadFill: roadFill,
        curbColor: curbColor,
        outlinePaint: outlinePaint,
        dashPaint: dashPaint,
      );
      return;
    }

    // Standard perspective road trapezoid
    final roadPath = Path()
      ..moveTo(w * 0.30, h * 0.12)
      ..lineTo(w * 0.70, h * 0.12)
      ..lineTo(w * 0.90, h * 0.88)
      ..lineTo(w * 0.10, h * 0.88)
      ..close();

    canvas.drawPath(roadPath, Paint()..color = roadFill);

    // Left & right road curbs
    final curbPaint = Paint()
      ..color = type == RoadDamageType.bergelombang
          ? const Color(0xFFEA580C)
          : curbColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.30, h * 0.12),
      Offset(w * 0.10, h * 0.88),
      curbPaint,
    );
    canvas.drawLine(
      Offset(w * 0.70, h * 0.12),
      Offset(w * 0.90, h * 0.88),
      curbPaint,
    );

    // Center dashed line (top + bottom segment)
    canvas.drawLine(
      Offset(w * 0.50, h * 0.16),
      Offset(w * 0.50, h * 0.28),
      dashPaint,
    );
    canvas.drawLine(
      Offset(w * 0.50, h * 0.74),
      Offset(w * 0.50, h * 0.86),
      dashPaint,
    );

    switch (type) {
      case RoadDamageType.berlubang:
        // Middle dash
        canvas.drawLine(
          Offset(w * 0.50, h * 0.44),
          Offset(w * 0.50, h * 0.56),
          dashPaint,
        );
        // Simple potholes (2 dark/water ovals)
        final holeFill = Paint()..color = const Color(0xFF475569);
        final puddleFill = Paint()..color = const Color(0xFF60A5FA);
        final hole1 = Rect.fromCenter(
          center: Offset(w * 0.34, h * 0.66),
          width: w * 0.24,
          height: h * 0.13,
        );
        canvas.drawOval(hole1, holeFill);
        canvas.drawOval(hole1, outlinePaint..strokeWidth = w * 0.05);

        final hole2 = Rect.fromCenter(
          center: Offset(w * 0.66, h * 0.46),
          width: w * 0.22,
          height: h * 0.12,
        );
        canvas.drawOval(hole2, puddleFill);
        canvas.drawOval(hole2, outlinePaint);

        final hole3 = Rect.fromCenter(
          center: Offset(w * 0.38, h * 0.34),
          width: w * 0.14,
          height: h * 0.08,
        );
        canvas.drawOval(hole3, holeFill);
        break;

      case RoadDamageType.bergelombang:
        // 2 simple wavy road bumps across the road
        final wavePaint = Paint()
          ..color = const Color(0xFFEA580C)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.095
          ..strokeCap = StrokeCap.round;

        for (final yOff in [0.42, 0.58]) {
          final wave = Path()
            ..moveTo(w * 0.22, h * yOff)
            ..cubicTo(
              w * 0.36,
              h * (yOff - 0.11),
              w * 0.44,
              h * (yOff + 0.11),
              w * 0.58,
              h * yOff,
            )
            ..quadraticBezierTo(
              w * 0.68,
              h * (yOff - 0.08),
              w * 0.78,
              h * yOff,
            );
          canvas.drawPath(wave, wavePaint);
        }
        break;

      case RoadDamageType.retak:
        // Simple branching crack across the center of the road
        final crackPaint = Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.065
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        final crack = Path()
          ..moveTo(w * 0.28, h * 0.36)
          ..lineTo(w * 0.42, h * 0.46)
          ..lineTo(w * 0.50, h * 0.49)
          ..lineTo(w * 0.68, h * 0.36)
          ..moveTo(w * 0.50, h * 0.49)
          ..lineTo(w * 0.32, h * 0.68)
          ..moveTo(w * 0.50, h * 0.49)
          ..lineTo(w * 0.62, h * 0.60)
          ..lineTo(w * 0.72, h * 0.66);
        canvas.drawPath(crack, crackPaint);
        break;

      case RoadDamageType.lainnya:
        // Middle dash
        canvas.drawLine(
          Offset(w * 0.50, h * 0.44),
          Offset(w * 0.50, h * 0.56),
          dashPaint,
        );
        // Simple "?" question mark on the right side
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFF2563EB),
              fontSize: h * 0.50,
              fontWeight: FontWeight.w900,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(w * 0.66 - tp.width / 2, h * 0.48 - tp.height / 2),
        );
        break;

      case RoadDamageType.amblesLongsor:
        break;
    }
  }

  void _drawAmblesLongsor(
    Canvas canvas,
    double w,
    double h, {
    required Color roadFill,
    required Color curbColor,
    required Paint outlinePaint,
    required Paint dashPaint,
  }) {
    // Intact left portion of the road
    final leftRoad = Path()
      ..moveTo(w * 0.30, h * 0.12)
      ..lineTo(w * 0.54, h * 0.12)
      ..lineTo(w * 0.54, h * 0.88)
      ..lineTo(w * 0.10, h * 0.88)
      ..close();
    canvas.drawPath(leftRoad, Paint()..color = roadFill);

    // Left curb (brownish/accent)
    canvas.drawLine(
      Offset(w * 0.30, h * 0.12),
      Offset(w * 0.10, h * 0.88),
      Paint()
        ..color = const Color(0xFF92400E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.09
        ..strokeCap = StrokeCap.round,
    );

    // Crack on left road
    final crack = Path()
      ..moveTo(w * 0.21, h * 0.52)
      ..lineTo(w * 0.38, h * 0.47)
      ..lineTo(w * 0.54, h * 0.53);
    canvas.drawPath(crack, outlinePaint..strokeWidth = w * 0.06);

    // Center dashed line on edge of break
    canvas.drawLine(
      Offset(w * 0.52, h * 0.18),
      Offset(w * 0.52, h * 0.32),
      dashPaint,
    );
    canvas.drawLine(
      Offset(w * 0.52, h * 0.66),
      Offset(w * 0.52, h * 0.82),
      dashPaint,
    );

    // Collapsed soil/landslide mound on right side
    final soilFill = Paint()..color = const Color(0xFFA16207);
    final soilPath = Path()
      ..moveTo(w * 0.56, h * 0.36)
      ..lineTo(w * 0.72, h * 0.54)
      ..lineTo(w * 0.90, h * 0.88)
      ..lineTo(w * 0.56, h * 0.88)
      ..close();
    canvas.drawPath(soilPath, soilFill);
    canvas.drawPath(soilPath, outlinePaint..strokeWidth = w * 0.055);

    // 2 small falling rock chunks
    canvas.drawCircle(Offset(w * 0.68, h * 0.32), w * 0.065, soilFill);
    canvas.drawCircle(Offset(w * 0.68, h * 0.32), w * 0.065, outlinePaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.48), w * 0.055, soilFill);
    canvas.drawCircle(Offset(w * 0.80, h * 0.48), w * 0.055, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _RoadDamageIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isSelected != isSelected;
  }
}
