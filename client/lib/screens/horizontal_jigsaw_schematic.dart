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
        final double effectiveWidth = availableWidth.isFinite
            ? availableWidth
            : 1000.0;

        const double fontSize = 10.0;
        const double overlap = 12.0;

        // 1. Measure Minimum Widths
        List<double> minWidths = List.filled(segments.length, 0.0);
        double totalMinWidth = 0.0;

        for (int i = 0; i < segments.length; i++) {
          final seg = segments[i];
          bool isFirst = i == 0;
          bool isLast = i == segments.length - 1;

          double paddingLeft = isFirst ? 6.0 : (overlap + 1.0);
          double paddingRight = isLast ? 6.0 : 2.0;

          // Icon (16) + Spacing (2)
          double contentBase = 16.0 + 2.0;

          final textPainter = TextPainter(
            text: TextSpan(
              text: seg.label,
              style: const TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();

          double minW = (paddingLeft + contentBase + textPainter.width + paddingRight + 0.5).ceilToDouble();
          minWidths[i] = minW;
          totalMinWidth += minW;
        }

        // 2. Check Constraint
        bool scrollNeeded = totalMinWidth > effectiveWidth;
        List<double> segmentWidths = List.filled(segments.length, 0.0);

        if (scrollNeeded) {
          // Use minWidth for every segment
          for (int i = 0; i < segments.length; i++) {
            segmentWidths[i] = minWidths[i];
          }
        } else {
          // 3. Distribute Bonus Space
          double bonusSpace = effectiveWidth - totalMinWidth;

          // Calculate sum of time for segments to distribute bonus proportionally
          double timeSum = segments.fold(0.0, (sum, s) => sum + s.time);
          if (timeSum <= 0) timeSum = 1.0; // Avoid division by zero

          for (int i = 0; i < segments.length; i++) {
            final seg = segments[i];
            double proportion = seg.time / timeSum;
            double share = proportion * bonusSpace;
            segmentWidths[i] = minWidths[i] + share;
          }
        }

        Widget content = Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments.asMap().entries.map((entry) {
            final index = entry.key;
            final seg = entry.value;
            final isFirst = index == 0;
            final isLast = index == segments.length - 1;

            double width = segmentWidths[index];

            Color color;
            try {
              color = Color(
                int.parse(seg.lineColor.replaceAll('#', ''), radix: 16) +
                    0xFF000000,
              );
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
                overlap: overlap,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getIconData(seg.iconId), color: textColor, size: 16),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        seg.label,
                        maxLines: 1,
                        style: TextStyle(
                          color: textColor,
                          fontSize: fontSize,
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

        if (scrollNeeded) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );
        }

        return content;
      },
    );
  }

  IconData _getIconData(String iconId) {
    switch (iconId) {
      case 'train':
        return LucideIcons.train;
      case 'bus':
        return LucideIcons.bus;
      case 'car':
        return LucideIcons.car;
      case 'bike':
        return LucideIcons.bike;
      case 'footprints':
        return LucideIcons.footprints;
      default:
        return LucideIcons.circle;
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
          left: isFirst ? 6 : (overlap + 1.0),
          right: isLast ? 6 : 2.0,
          top: 1,
          bottom: 1,
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
    final r = 8.0; // Fixed radius for rounded rectangle ends

    // Start Left
    if (isFirst) {
      path.moveTo(0, r);
      path.arcToPoint(Offset(r, 0), radius: Radius.circular(r));
    } else {
      path.moveTo(0, 0);
    }

    // Top Edge
    if (isLast) {
      path.lineTo(w - r, 0);
      path.arcToPoint(Offset(w, r), radius: Radius.circular(r));
    } else {
      path.lineTo(w, 0);
    }

    // Right Edge
    if (isLast) {
      path.lineTo(w, h - r);
      path.arcToPoint(Offset(w - r, h), radius: Radius.circular(r));
    } else {
      // Convex Right (Bubble Out)
      // Bezier curve sticking out to w + o
      // We start at (w, 0)
      // End at (w, h)
      // Control point around (w + o * 1.5, h / 2) - original was (w+o, h/2)
      path.quadraticBezierTo(w + o, h / 2, w, h);
    }

    // Bottom Edge
    if (isFirst) {
      path.lineTo(r, h);
      path.arcToPoint(Offset(0, h - r), radius: Radius.circular(r));
    } else {
      path.lineTo(0, h);
    }

    // Left Edge
    if (isFirst) {
      path.lineTo(0, r); // Close loop
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
