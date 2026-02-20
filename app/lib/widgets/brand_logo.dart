import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SwiftFoxPainter(),
      ),
    );
  }
}

class _SwiftFoxPainter extends CustomPainter {
  static const Color foxGreen = Color(0xFF006B3D);
  static const Color foxCoral = Color(0xFFFF6B6B);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final greenPaint = Paint()..color = foxGreen..style = PaintingStyle.fill;
    final coralPaint = Paint()..color = foxCoral..style = PaintingStyle.fill;
    final whitePaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Face circle - takes up most of the space
    final faceCenter = Offset(w * 0.5, h * 0.58);
    final faceRadius = w * 0.38;
    canvas.drawCircle(faceCenter, faceRadius, greenPaint);

    // Left ear - triangle
    final leftEarPath = Path()
      ..moveTo(w * 0.18, h * 0.48)   // bottom-left
      ..lineTo(w * 0.28, h * 0.12)   // tip
      ..lineTo(w * 0.40, h * 0.38)   // bottom-right
      ..close();
    canvas.drawPath(leftEarPath, greenPaint);

    // Right ear - triangle
    final rightEarPath = Path()
      ..moveTo(w * 0.60, h * 0.38)   // bottom-left
      ..lineTo(w * 0.72, h * 0.12)   // tip
      ..lineTo(w * 0.82, h * 0.48)   // bottom-right
      ..close();
    canvas.drawPath(rightEarPath, greenPaint);

    // Left inner ear - coral
    final leftInnerEarPath = Path()
      ..moveTo(w * 0.22, h * 0.44)
      ..lineTo(w * 0.28, h * 0.20)
      ..lineTo(w * 0.37, h * 0.38)
      ..close();
    canvas.drawPath(leftInnerEarPath, coralPaint);

    // Right inner ear - coral
    final rightInnerEarPath = Path()
      ..moveTo(w * 0.63, h * 0.38)
      ..lineTo(w * 0.72, h * 0.20)
      ..lineTo(w * 0.78, h * 0.44)
      ..close();
    canvas.drawPath(rightInnerEarPath, coralPaint);

    // Left eye - white circle
    canvas.drawCircle(Offset(w * 0.38, h * 0.54), w * 0.08, whitePaint);
    // Left pupil - coral dot
    canvas.drawCircle(Offset(w * 0.38, h * 0.54), w * 0.04, coralPaint);

    // Right eye - white circle
    canvas.drawCircle(Offset(w * 0.62, h * 0.54), w * 0.08, whitePaint);
    // Right pupil - coral dot
    canvas.drawCircle(Offset(w * 0.62, h * 0.54), w * 0.04, coralPaint);

    // Snout - slightly lighter circle at bottom of face
    final snoutPaint = Paint()..color = const Color(0xFF00844A)..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.5, h * 0.72), w * 0.16, snoutPaint);

    // Nose - small coral triangle
    final nosePath = Path()
      ..moveTo(w * 0.5, h * 0.65)
      ..lineTo(w * 0.44, h * 0.72)
      ..lineTo(w * 0.56, h * 0.72)
      ..close();
    canvas.drawPath(nosePath, coralPaint);
  }

  @override
  bool shouldRepaint(_SwiftFoxPainter oldDelegate) => false;
}
