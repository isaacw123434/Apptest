import 'package:flutter/material.dart';

class JigsawSegment extends StatelessWidget {
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final Color backgroundColor;
  final Color borderColor;
  final double tabHeight;

  const JigsawSegment({
    super.key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor = Colors.white,
    this.borderColor = const Color(0xFFE2E8F0), // Slate 200
    this.tabHeight = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _JigsawPainter(
        isFirst: isFirst,
        isLast: isLast,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        tabHeight: tabHeight,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: isFirst ? 16 : (tabHeight + 8),
          bottom: isLast ? 16 : (tabHeight + 8),
          left: 16,
          right: 16,
        ),
        child: child,
      ),
    );
  }
}

class _JigsawPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color backgroundColor;
  final Color borderColor;
  final double tabHeight;

  _JigsawPainter({
    required this.isFirst,
    required this.isLast,
    required this.backgroundColor,
    required this.borderColor,
    required this.tabHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = _getPath(size);

    // Draw fill
    canvas.drawPath(path, paint);

    // Draw border
    canvas.drawPath(path, borderPaint);
  }

  Path _getPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final t = tabHeight;
    final r = 16.0; // Corner radius

    // Start Top Left
    if (isFirst) {
      path.moveTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0); // Top Left Corner
    } else {
      path.moveTo(0, 0);
    }

    // Top Edge
    if (isFirst) {
      path.lineTo(w - r, 0);
      path.quadraticBezierTo(w, 0, w, r); // Top Right Corner
    } else {
      // Top Slot (Inward)
      path.lineTo(w / 2 - t, 0);
      path.cubicTo(
        w / 2 - t, t,
        w / 2 + t, t,
        w / 2 + t, 0
      );
      path.lineTo(w, 0);
    }

    // Right Edge
    if (isLast) {
      path.lineTo(w, h - r);
      path.quadraticBezierTo(w, h, w - r, h); // Bottom Right Corner
    } else {
      path.lineTo(w, h);
    }

    // Bottom Edge
    if (isLast) {
      path.lineTo(r, h);
      path.quadraticBezierTo(0, h, 0, h - r); // Bottom Left Corner
    } else {
      // Bottom Tab (Outward)
      path.lineTo(w / 2 + t, h);
      path.cubicTo(
        w / 2 + t, h + t,
        w / 2 - t, h + t,
        w / 2 - t, h
      );
      path.lineTo(0, h);
    }

    // Left Edge
    if (isFirst) {
      // Already handled start
    } else {
      path.lineTo(0, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
