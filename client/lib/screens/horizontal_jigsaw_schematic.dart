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

        // Minimal width for icon + text
        const double minSegmentWidth = 70.0;

        // Calculate widths
        Map<Segment, double> segmentWidths = {};

        double totalMinWidth = segments.length * minSegmentWidth;

        if (totalMinWidth > effectiveWidth) {
           // If we can't fit even with min width, distribute equally
           for (var seg in segments) {
             segmentWidths[seg] = effectiveWidth / segments.length;
           }
        } else {
           // Iterative distribution
           // 1. Sort segments by time to handle smallest first
           List<Segment> sortedSegments = List.from(segments);
           sortedSegments.sort((a, b) => a.time.compareTo(b.time));

           double remainingWidth = effectiveWidth;
           double remainingTime = totalTime > 0 ? totalTime : 1;
           Set<Segment> handled = {};

           // Pass 1: Assign min width to small segments
           for (var seg in sortedSegments) {
              if (remainingTime <= 0) break;
              double propWidth = (seg.time / remainingTime) * remainingWidth;

              // Ideally, if propWidth < minSegmentWidth, we give it minSegmentWidth.
              // But we must check if remaining space allows it.
              // Actually, since we know totalMinWidth <= effectiveWidth, we have enough space for everyone to be at least minSegmentWidth.

              if (propWidth < minSegmentWidth) {
                 segmentWidths[seg] = minSegmentWidth;
                 remainingWidth -= minSegmentWidth;
                 remainingTime -= seg.time;
                 handled.add(seg);
              }
           }

           // Pass 2: Distribute remaining width to others
           for (var seg in segments) {
              if (!handled.contains(seg)) {
                 double w = (seg.time / remainingTime) * remainingWidth;
                 segmentWidths[seg] = w;
              }
           }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments.asMap().entries.map((entry) {
            final index = entry.key;
            final seg = entry.value;
            final isFirst = index == 0;
            final isLast = index == segments.length - 1;

            double width = segmentWidths[seg] ?? minSegmentWidth;

            Color color;
            try {
              color = Color(int.parse(seg.lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
            } catch (e) {
              color = Colors.grey;
            }

            // Text color needs to contrast with background.
            final isBright = color.computeLuminance() > 0.5;
            final textColor = isBright ? Colors.black : Colors.white;

            return SizedBox(
              width: width,
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
