import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Decorative background for Login and Register pages.
///
/// Combines the airy, layered floating-card composition (warm top-right sun
/// glow, stylized clouds, and curved bottom horizon) with road construction
/// elements (tower cranes, city skyline, asphalt road, barrier, sand pile &
/// shovel, roadwork & STOP signs, surveying tripod, traffic cones, and
/// excavator).
class AuthRoadBackground extends StatelessWidget {
  const AuthRoadBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(painter: _AuthRoadPainter()),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}

class _AuthRoadPainter extends CustomPainter {
  const _AuthRoadPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Base clean white/off-white canvas
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFFCFEFF),
    );

    // 2. Top-right pastel sun & sky glow (inspired by Image 1 + Image 2 sky)
    _drawTopSkyAndSun(canvas, w, h);

    // 3. Faint city skyline & tower cranes in upper-right sky (from Image 2)
    _drawSkylineAndCranes(canvas, w, h);

    // 4. Stylized clouds (Image 1 positioning + Image 2 cloud silhouette)
    _drawClouds(canvas, w, h);

    // 5. Subtle winding highway loop on upper-left edge (from Image 2)
    _drawWindingRoadAccent(canvas, w, h);

    // 6. Bottom curved hill + asphalt road + roadwork elements (Image 1 curve + Image 2 elements)
    _drawBottomRoadScene(canvas, w, h);
  }

  void _drawTopSkyAndSun(Canvas canvas, double w, double h) {
    // Soft cyan-mint sky wash on top-right
    final skyRect = Rect.fromLTWH(0, 0, w, h * 0.42);
    final skyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.85, -0.85),
        radius: 1.25,
        colors: [
          const Color(0xFFD5F0F4).withValues(alpha: 0.90),
          const Color(0xFFEAF7F8).withValues(alpha: 0.65),
          const Color(0xFFFCFEFF).withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(skyRect);
    canvas.drawRect(skyRect, skyPaint);

    // Concentric warm sun arcs in the top-right corner (like Image 1)
    final sunCenter = Offset(w * 0.94, h * 0.05);
    final sunRadii = [w * 0.36, w * 0.27, w * 0.19, w * 0.12];
    final sunColors = [
      const Color(0xFFFFF1DF).withValues(alpha: 0.55),
      const Color(0xFFFFDFC2).withValues(alpha: 0.55),
      const Color(0xFFFFC599).withValues(alpha: 0.50),
      const Color(0xFFFF9F76).withValues(alpha: 0.55),
    ];

    for (var i = 0; i < sunRadii.length; i++) {
      canvas.drawCircle(sunCenter, sunRadii[i], Paint()..color = sunColors[i]);
    }
  }

  void _drawSkylineAndCranes(Canvas canvas, double w, double h) {
    final silhouetteColor = const Color(0xFFB5DDE3).withValues(alpha: 0.55);
    final silhouettePaint = Paint()..color = silhouetteColor;
    final baseY = h * 0.25;

    // Faint city buildings on upper-right
    final buildings = [
      Rect.fromLTWH(w * 0.56, baseY - 38, 18, 38),
      Rect.fromLTWH(w * 0.62, baseY - 54, 22, 54),
      Rect.fromLTWH(w * 0.69, baseY - 30, 16, 30),
      Rect.fromLTWH(w * 0.75, baseY - 62, 24, 62),
      Rect.fromLTWH(w * 0.83, baseY - 44, 20, 44),
      Rect.fromLTWH(w * 0.90, baseY - 50, 22, 50),
    ];
    for (final b in buildings) {
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          b,
          topLeft: const Radius.circular(2),
          topRight: const Radius.circular(2),
        ),
        silhouettePaint,
      );
    }

    // Tower crane 1 (upper right)
    _drawTowerCrane(
      canvas,
      base: Offset(w * 0.78, baseY),
      mastHeight: 74,
      jibLength: 62,
      counterJib: 20,
      color: const Color(0xFF9ACFD8).withValues(alpha: 0.7),
    );

    // Tower crane 2 (smaller, further right)
    _drawTowerCrane(
      canvas,
      base: Offset(w * 0.91, baseY),
      mastHeight: 54,
      jibLength: 44,
      counterJib: 14,
      color: const Color(0xFFAAD9E1).withValues(alpha: 0.65),
    );
  }

  void _drawTowerCrane(
    Canvas canvas, {
    required Offset base,
    required double mastHeight,
    required double jibLength,
    required double counterJib,
    required Color color,
  }) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final top = Offset(base.dx, base.dy - mastHeight);
    final jibEnd = Offset(base.dx - jibLength, top.dy + 6);
    final counterEnd = Offset(base.dx + counterJib, top.dy + 4);
    final peak = Offset(base.dx, top.dy - 12);

    // Mast
    canvas.drawLine(base, top, stroke);
    canvas.drawLine(
      Offset(base.dx - 4, base.dy),
      Offset(top.dx - 2, top.dy),
      stroke..strokeWidth = 1.4,
    );

    // Jib & counter-jib
    canvas.drawLine(counterEnd, jibEnd, stroke..strokeWidth = 2.2);
    // Support cables
    canvas.drawLine(
      peak,
      Offset(jibEnd.dx + 8, jibEnd.dy),
      stroke..strokeWidth = 1.1,
    );
    canvas.drawLine(peak, counterEnd, stroke);
    // Hanging hook cable
    final hookX = base.dx - jibLength * 0.65;
    canvas.drawLine(
      Offset(hookX, top.dy + 5),
      Offset(hookX, top.dy + 24),
      stroke..strokeWidth = 1.1,
    );
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    // Cloud 1: Top-right teal-cyan cloud (like Image 1, flat-bottomed like Image 2)
    _drawFlatCloud(
      canvas,
      center: Offset(w * 0.78, h * 0.165),
      scale: 1.05,
      gradientColors: [const Color(0xFF39A7BD), const Color(0xFF7CD4DF)],
    );

    // Cloud 2: Upper-left softer cloud peeking near header/card
    _drawFlatCloud(
      canvas,
      center: Offset(w * 0.17, h * 0.22),
      scale: 0.92,
      gradientColors: [const Color(0xFF4BB6C9), const Color(0xFF9BE0E8)],
    );

    // Cloud 3: Small white distant cloud
    _drawFlatCloud(
      canvas,
      center: Offset(w * 0.50, h * 0.11),
      scale: 0.55,
      gradientColors: [
        Colors.white.withValues(alpha: 0.95),
        const Color(0xFFE2F4F7),
      ],
    );
  }

  void _drawFlatCloud(
    Canvas canvas, {
    required Offset center,
    required double scale,
    required List<Color> gradientColors,
  }) {
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;
    final s = scale;

    path.moveTo(cx - 48 * s, cy + 14 * s);
    path.arcToPoint(
      Offset(cx - 32 * s, cy - 8 * s),
      radius: Radius.circular(18 * s),
    );
    path.arcToPoint(
      Offset(cx - 4 * s, cy - 22 * s),
      radius: Radius.circular(22 * s),
    );
    path.arcToPoint(
      Offset(cx + 28 * s, cy - 10 * s),
      radius: Radius.circular(20 * s),
    );
    path.arcToPoint(
      Offset(cx + 46 * s, cy + 14 * s),
      radius: Radius.circular(16 * s),
    );
    path.close();

    final bounds = path.getBounds();
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: gradientColors,
      ).createShader(bounds);

    canvas.drawPath(path, paint);
  }

  void _drawWindingRoadAccent(Canvas canvas, double w, double h) {
    // Subtle looping road ribbon on the upper-left edge (inspired by Image 2)
    final roadPaint = Paint()
      ..color = const Color(0xFF94A3B8).withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(-12, h * 0.08)
      ..quadraticBezierTo(w * 0.12, h * 0.06, w * 0.11, h * 0.15)
      ..arcToPoint(
        Offset(w * 0.03, h * 0.15),
        radius: const Radius.circular(22),
        clockwise: false,
      )
      ..lineTo(-12, h * 0.15);

    canvas.drawPath(path, roadPaint);

    // Subtle dashed center line
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      double d = 4;
      while (d < metric.length) {
        final seg = metric.extractPath(d, math.min(d + 7, metric.length));
        canvas.drawPath(seg, dashPaint);
        d += 14;
      }
    }
  }

  void _drawBottomRoadScene(Canvas canvas, double w, double h) {
    final hillTopY = h * 0.855;
    final roadTopY = h * 0.905;

    // 1. Curved green/olive ground hill at the bottom (Image 1 curve + Image 2 grass color)
    final hillPath = Path()
      ..moveTo(0, hillTopY + 18)
      ..quadraticBezierTo(w * 0.5, hillTopY - 26, w, hillTopY + 12)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    final hillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFC8DE6B), Color(0xFFA3C94B)],
      ).createShader(Rect.fromLTWH(0, hillTopY - 26, w, h - hillTopY + 26));
    canvas.drawPath(hillPath, hillPaint);

    // 2. Road construction props standing along the curved horizon
    // Left: Road barrier + sand pile + shovel
    _drawRoadBarrier(canvas, Offset(w * 0.12, hillTopY + 4));
    _drawSandPile(canvas, Offset(w * 0.19, hillTopY + 14), 34, 16);
    _drawShovel(canvas, Offset(w * 0.17, hillTopY + 10), angle: -0.35);

    // Center-left: Surveying tripod (total station) & leveling staff
    _drawSurveyingTripod(canvas, Offset(w * 0.34, hillTopY + 2));

    // Center-right: Roadwork triangle sign & STOP sign
    _drawRoadworkSign(canvas, Offset(w * 0.54, hillTopY - 4));
    _drawStopSign(canvas, Offset(w * 0.63, hillTopY - 6));

    // Right: Sand mound & Excavator
    _drawSandPile(canvas, Offset(w * 0.74, hillTopY + 10), 42, 18);
    _drawExcavator(canvas, Offset(w * 0.84, hillTopY + 6));

    // 3. Asphalt road band across the bottom
    final roadPath = Path()
      ..moveTo(0, roadTopY + 6)
      ..quadraticBezierTo(w * 0.5, roadTopY - 6, w, roadTopY + 4)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(roadPath, Paint()..color = const Color(0xFF7B8191));

    // Darker foreground asphalt strip
    final lowerRoadRect = Rect.fromLTWH(
      0,
      roadTopY + 24,
      w,
      h - (roadTopY + 24),
    );
    canvas.drawRect(lowerRoadRect, Paint()..color = const Color(0xFF636877));

    // Pothole/asphalt patches (from Image 2)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.28, roadTopY + 38),
        width: 52,
        height: 10,
      ),
      Paint()..color = const Color(0xFF4F5461),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.72, roadTopY + 42),
        width: 64,
        height: 11,
      ),
      Paint()..color = const Color(0xFF4F5461),
    );

    // White dashed lane line
    final dashY = roadTopY + 24;
    final dashPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    double x = 8;
    while (x < w) {
      canvas.drawLine(
        Offset(x, dashY),
        Offset(math.min(x + 18, w), dashY),
        dashPaint,
      );
      x += 32;
    }

    // Traffic cones along the road
    _drawTrafficCone(canvas, Offset(w * 0.45, roadTopY + 22), scale: 0.95);
    _drawTrafficCone(canvas, Offset(w * 0.90, roadTopY + 16), scale: 0.80);

    // Yellow-black hazard stripe at bottom-right corner (from Image 2)
    _drawHazardStripe(canvas, w, h);
  }

  void _drawRoadBarrier(Canvas canvas, Offset base) {
    final legPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(base.dx - 16, base.dy),
      Offset(base.dx - 16, base.dy - 22),
      legPaint,
    );
    canvas.drawLine(
      Offset(base.dx + 16, base.dy),
      Offset(base.dx + 16, base.dy - 22),
      legPaint,
    );

    final boardRect = Rect.fromCenter(
      center: Offset(base.dx, base.dy - 17),
      width: 42,
      height: 11,
    );
    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(boardRect, const Radius.circular(2)),
    );
    canvas.drawRect(boardRect, Paint()..color = Colors.white);
    final stripePaint = Paint()..color = const Color(0xFFE04F3E);
    for (double sx = boardRect.left - 12; sx < boardRect.right + 12; sx += 10) {
      final stripe = Path()
        ..moveTo(sx, boardRect.bottom)
        ..lineTo(sx + 5, boardRect.bottom)
        ..lineTo(sx + 11, boardRect.top)
        ..lineTo(sx + 6, boardRect.top)
        ..close();
      canvas.drawPath(stripe, stripePaint);
    }
    canvas.restore();
  }

  void _drawSandPile(Canvas canvas, Offset base, double width, double height) {
    final path = Path()
      ..moveTo(base.dx - width / 2, base.dy)
      ..quadraticBezierTo(
        base.dx,
        base.dy - height * 1.4,
        base.dx + width / 2,
        base.dy,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFF6C358), Color(0xFFE39E2B)],
        ).createShader(path.getBounds()),
    );
  }

  void _drawShovel(Canvas canvas, Offset tip, {required double angle}) {
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(angle);

    // Wooden handle
    canvas.drawLine(
      const Offset(0, -6),
      const Offset(0, -28),
      Paint()
        ..color = const Color(0xFF8B5A2B)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Handle grip
    canvas.drawLine(
      const Offset(-3, -28),
      const Offset(3, -28),
      Paint()
        ..color = const Color(0xFF475569)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );
    // Blade
    final blade = Path()
      ..moveTo(-5, -8)
      ..lineTo(5, -8)
      ..lineTo(3, 2)
      ..lineTo(-3, 2)
      ..close();
    canvas.drawPath(blade, Paint()..color = const Color(0xFF94A3B8));
    canvas.restore();
  }

  void _drawSurveyingTripod(Canvas canvas, Offset base) {
    final legPaint = Paint()
      ..color = const Color(0xFFE5C17B)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    final top = Offset(base.dx, base.dy - 30);
    canvas.drawLine(top, Offset(base.dx - 10, base.dy + 4), legPaint);
    canvas.drawLine(top, Offset(base.dx + 10, base.dy + 4), legPaint);
    canvas.drawLine(
      top,
      Offset(base.dx, base.dy + 2),
      legPaint..color = const Color(0xFFCBA052),
    );

    // Theodolite head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(top.dx, top.dy - 6),
          width: 12,
          height: 11,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFE59E23),
    );
    canvas.drawCircle(
      Offset(top.dx, top.dy - 6),
      3,
      Paint()..color = const Color(0xFF334155),
    );

    // Leveling staff beside tripod
    final staffRect = Rect.fromLTWH(base.dx + 14, base.dy - 26, 4.5, 30);
    canvas.drawRect(staffRect, Paint()..color = Colors.white);
    canvas.drawRect(
      staffRect,
      Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
    for (double y = staffRect.top + 3; y < staffRect.bottom - 2; y += 6) {
      canvas.drawRect(
        Rect.fromLTWH(staffRect.left + 0.5, y, 3.5, 2.5),
        Paint()..color = const Color(0xFFE04F3E),
      );
    }
  }

  void _drawRoadworkSign(Canvas canvas, Offset base) {
    // Post
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - 30),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 2.5,
    );

    // Red-bordered white triangle
    final center = Offset(base.dx, base.dy - 32);
    final tri = Path()
      ..moveTo(center.dx, center.dy - 14)
      ..lineTo(center.dx + 13, center.dy + 9)
      ..lineTo(center.dx - 13, center.dy + 9)
      ..close();
    canvas.drawPath(tri, Paint()..color = Colors.white);
    canvas.drawPath(
      tri,
      Paint()
        ..color = const Color(0xFFE04F3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeJoin = StrokeJoin.round,
    );

    // Minimal worker silhouette inside triangle
    canvas.drawCircle(
      Offset(center.dx - 1, center.dy - 2),
      2.2,
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawLine(
      Offset(center.dx - 1, center.dy),
      Offset(center.dx + 3, center.dy + 6),
      Paint()
        ..color = const Color(0xFF1E293B)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStopSign(Canvas canvas, Offset base) {
    // Post
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - 34),
      Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = 2.8,
    );

    // Octagon
    final c = Offset(base.dx, base.dy - 44);
    const r = 13.0;
    final oct = Path();
    for (var i = 0; i < 8; i++) {
      final a = (math.pi / 8) + i * (math.pi / 4);
      final pt = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        oct.moveTo(pt.dx, pt.dy);
      } else {
        oct.lineTo(pt.dx, pt.dy);
      }
    }
    oct.close();
    canvas.drawPath(oct, Paint()..color = const Color(0xFFE04F3E));
    canvas.drawPath(
      oct,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // White "STOP" bar/text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'STOP',
        style: TextStyle(
          color: Colors.white,
          fontSize: 6.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  void _drawExcavator(Canvas canvas, Offset base) {
    // Tracks
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 4),
          width: 38,
          height: 9,
        ),
        const Radius.circular(4.5),
      ),
      Paint()..color = const Color(0xFF334155),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(base.dx, base.dy - 4),
          width: 28,
          height: 4,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF64748B),
    );

    // Body & cab
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 12, base.dy - 21, 26, 13),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFF5A623),
    );
    // Cab window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(base.dx - 10, base.dy - 19, 10, 8),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF93C5FD),
    );

    // Boom & arm
    final boomPaint = Paint()
      ..color = const Color(0xFFD98218)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final armPath = Path()
      ..moveTo(base.dx - 12, base.dy - 15)
      ..lineTo(base.dx - 24, base.dy - 30)
      ..lineTo(base.dx - 34, base.dy - 14);
    canvas.drawPath(armPath, boomPaint);

    // Bucket
    final bucket = Path()
      ..moveTo(base.dx - 34, base.dy - 14)
      ..lineTo(base.dx - 41, base.dy - 11)
      ..lineTo(base.dx - 37, base.dy - 4)
      ..lineTo(base.dx - 31, base.dy - 9)
      ..close();
    canvas.drawPath(bucket, Paint()..color = const Color(0xFF475569));
  }

  void _drawTrafficCone(Canvas canvas, Offset base, {double scale = 1.0}) {
    canvas.save();
    canvas.translate(base.dx, base.dy);
    canvas.scale(scale);

    // Base plate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: const Offset(0, 0), width: 18, height: 4),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF334155),
    );

    // Cone body
    final cone = Path()
      ..moveTo(-7, -1)
      ..lineTo(-2, -22)
      ..lineTo(2, -22)
      ..lineTo(7, -1)
      ..close();
    canvas.drawPath(cone, Paint()..color = const Color(0xFFF97316));

    // Black/white stripes clipped inside cone
    canvas.save();
    canvas.clipPath(cone);
    canvas.drawRect(
      const Rect.fromLTWH(-8, -16, 16, 4),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.drawRect(
      const Rect.fromLTWH(-8, -9, 16, 4),
      Paint()..color = const Color(0xFF1E293B),
    );
    canvas.restore();
    canvas.restore();
  }

  void _drawHazardStripe(Canvas canvas, double w, double h) {
    final strip = Path()
      ..moveTo(w * 0.72, h)
      ..lineTo(w, h - 18)
      ..lineTo(w, h - 7)
      ..lineTo(w * 0.82, h)
      ..close();
    canvas.save();
    canvas.clipPath(strip);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.7, h - 22, w * 0.3, 24),
      Paint()..color = const Color(0xFFFACC15),
    );
    final dark = Paint()..color = const Color(0xFF1E293B);
    for (double x = w * 0.7; x < w + 20; x += 14) {
      final bar = Path()
        ..moveTo(x, h)
        ..lineTo(x + 7, h)
        ..lineTo(x + 15, h - 22)
        ..lineTo(x + 8, h - 22)
        ..close();
      canvas.drawPath(bar, dark);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
