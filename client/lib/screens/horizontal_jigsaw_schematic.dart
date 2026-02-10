import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';

class HorizontalJigsawSchematic extends StatelessWidget {
  final List<Segment> segments;
  final double totalTime;

  const HorizontalJigsawSchematic({
    super.key,
    required this.segments,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    // Determine flex values based on time
    double tTime = totalTime > 0 ? totalTime : 1;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: segments.asMap().entries.map((entry) {
        final index = entry.key;
        final seg = entry.value;
        final isFirst = index == 0;
        final isLast = index == segments.length - 1;

        final flex = (seg.time / tTime * 100).ceil();

        Color color;
        try {
          color = Color(int.parse(seg.lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
        } catch (e) {
          color = Colors.grey;
        }

        return Expanded(
          flex: flex > 0 ? flex : 1,
          child: HorizontalJigsawSegment(
            isFirst: isFirst,
            isLast: isLast,
            backgroundColor: color,
            borderColor: Colors.white, // Segments usually separated by white in jigsaw
            child: Center(
              child: Icon(
                _getIconData(seg.iconId),
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconData(String iconId) {
    switch (iconId) {
      case 'train': return LucideIcons.train;
      case 'bus': return LucideIcons.bus;
      case 'car': return LucideIcons.car;
      case 'bike': return LucideIcons.bike;
      case 'footprints': return LucideIcons.footprints;
      default: return LucideIcons.circle;
    }
  }
}

class HorizontalJigsawSegment extends StatelessWidget {
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final Color backgroundColor;
  final Color borderColor;
  final double tabWidth;

  const HorizontalJigsawSegment({
    super.key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor = Colors.blue,
    this.borderColor = Colors.white,
    this.tabWidth = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizontalJigsawPainter(
        isFirst: isFirst,
        isLast: isLast,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        tabWidth: tabWidth,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isFirst ? 4 : (tabWidth + 4),
          right: isLast ? 4 : (tabWidth + 4),
          top: 4,
          bottom: 4,
        ),
        child: child,
      ),
    );
  }
}

class _HorizontalJigsawPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color backgroundColor;
  final Color borderColor;
  final double tabWidth;

  _HorizontalJigsawPainter({
    required this.isFirst,
    required this.isLast,
    required this.backgroundColor,
    required this.borderColor,
    required this.tabWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Minimal border between segments

    final path = _getPath(size);

    canvas.drawPath(path, paint);
    // Optional: Draw border if needed, but usually jigsaw pieces fit tight.
    // If we want a white gap line, we can draw it.
    // canvas.drawPath(path, borderPaint);
  }

  Path _getPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final t = tabWidth;
    final r = 8.0; // Corner radius

    // Start Top Left
    if (isFirst) {
      path.moveTo(r, 0);
    } else {
      path.moveTo(0, 0);
    }

    // Top Edge
    path.lineTo(isLast ? w - r : w, 0);

    // Right Edge
    if (isLast) {
      path.quadraticBezierTo(w, 0, w, r); // Top Right Corner
      path.lineTo(w, h - r);
      path.quadraticBezierTo(w, h, w - r, h); // Bottom Right Corner
    } else {
      // Right Tab (Outward)
      path.lineTo(w, h / 2 - t);
      path.cubicTo(
        w + t, h / 2 - t,
        w + t, h / 2 + t,
        w, h / 2 + t
      );
      path.lineTo(w, h);
    }

    // Bottom Edge
    path.lineTo(isFirst ? r : 0, h);

    // Left Edge
    if (isFirst) {
      path.quadraticBezierTo(0, h, 0, h - r); // Bottom Left Corner
      path.lineTo(0, r);
      path.quadraticBezierTo(0, 0, r, 0); // Top Left Corner
    } else {
      // Left Slot (Inward) - Must match the Outward tab of the previous piece
      path.lineTo(0, h / 2 + t);
      path.cubicTo(
        t, h / 2 + t,
        t, h / 2 - t,
        0, h / 2 - t
      );
      path.lineTo(0, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
