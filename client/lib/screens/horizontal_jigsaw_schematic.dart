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
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // If availableWidth is infinite (e.g. in scroll view), use a default or screen width
        final double effectiveWidth = availableWidth.isFinite ? availableWidth : 1000.0;

        // Calculate minimal widths
        // 40 for icon + some text. Adjust as needed.
        const double minSegmentWidth = 90.0;

        // Total min width
        double totalMinWidth = segments.length * minSegmentWidth;

        bool canFit = totalMinWidth <= effectiveWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: canFit ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: segments.asMap().entries.map((entry) {
              final index = entry.key;
              final seg = entry.value;
              final isFirst = index == 0;
              final isLast = index == segments.length - 1;

              double width;
              if (canFit) {
                 // Proportional
                 double flex = (seg.time / (totalTime > 0 ? totalTime : 1));
                 width = effectiveWidth * flex;
                 if (width < minSegmentWidth) width = minSegmentWidth;

                 // Re-adjust?
                 // If we clamp to minWidth, total might exceed effectiveWidth.
                 // Simple approach: Use constrained width.
              } else {
                width = minSegmentWidth;
                // Or proportional scaled up?
                // Let's stick to minWidth if we scroll, or a bit more if time is long.
                 double flex = (seg.time / (totalTime > 0 ? totalTime : 1));
                 double propWidth = effectiveWidth * flex;
                 width = propWidth > minSegmentWidth ? propWidth : minSegmentWidth;
              }

              Color color;
              try {
                color = Color(int.parse(seg.lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
              } catch (e) {
                color = Colors.grey;
              }

              // Text color needs to contrast with background.
              final isBright = color.computeLuminance() > 0.5;
              final textColor = isBright ? Colors.black : Colors.white;

              return Container(
                width: width,
                constraints: BoxConstraints(minWidth: minSegmentWidth),
                child: HorizontalJigsawSegment(
                  isFirst: isFirst,
                  isLast: isLast,
                  backgroundColor: color,
                  borderColor: Colors.white,
                  overlap: 12.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconData(seg.iconId),
                        color: textColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          seg.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
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
  final double overlap;

  const HorizontalJigsawSegment({
    super.key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor = Colors.blue,
    this.borderColor = Colors.white,
    this.overlap = 12.0,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _HorizontalJigsawPainter(
        isFirst: isFirst,
        isLast: isLast,
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        overlap: overlap,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: isFirst ? 20 : (overlap + 4),
          right: isLast ? 20 : (overlap + 4),
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
  final double overlap;

  _HorizontalJigsawPainter({
    required this.isFirst,
    required this.isLast,
    required this.backgroundColor,
    required this.borderColor,
    required this.overlap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    // We don't draw border for now as it complicates the overlap.
    // If we need a white separator, we can stroke the path.
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final path = _getPath(size);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  Path _getPath(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final o = overlap;
    final r = h / 2; // Fully rounded ends

    // Start Left
    if (isFirst) {
      path.moveTo(r, 0);
    } else {
      path.moveTo(0, 0);
    }

    // Top Edge
    if (isLast) {
      path.lineTo(w - r, 0);
    } else {
      path.lineTo(w, 0);
    }

    // Right Edge
    if (isLast) {
      // Fully rounded end (semi-circle)
      path.arcToPoint(
        Offset(w - r, h),
        radius: Radius.circular(r),
        clockwise: true,
      );
    } else {
      // Convex Right (Bubble Out)
      // Bezier curve sticking out to w + o
      // We start at (w, 0)
      // End at (w, h)
      // Control point around (w + o * 1.5, h / 2)
      path.quadraticBezierTo(w + o, h / 2, w, h);
    }

    // Bottom Edge
    if (isFirst) {
      path.lineTo(r, h);
    } else {
      path.lineTo(0, h);
    }

    // Left Edge
    if (isFirst) {
      // Fully rounded start (semi-circle)
      path.arcToPoint(
        Offset(r, 0),
        radius: Radius.circular(r),
        clockwise: true,
      );
    } else {
      // Concave Left (Bubble In / Slot)
      // Matches the Convex Right of previous.
      // Start at (0, h). End at (0, 0).
      // Curve inwards to (o, h/2).
      path.quadraticBezierTo(o, h / 2, 0, 0);
    }

    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
