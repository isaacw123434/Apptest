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

        // Font size Fallback: If the sum of all "Snug Minimums" exceeds the screen width, decrease the font size until it fits
        double fontSize = 10.0;
        const double minFontSize = 8.0;

        // Map to store snug minimum widths
        Map<Segment, double> snugMinimums = {};

        // Helper to calculate snug minimum for a segment given a font size
        double calculateSnugMinimum(Segment seg, double fs) {
          int index = segments.indexOf(seg);
          bool isFirst = index == 0;
          bool isLast = index == segments.length - 1;
          // Overlap used in HorizontalJigsawSegment
          const double overlap = 12.0;

          // Padding logic matches HorizontalJigsawSegment
          double paddingLeft = isFirst ? 20.0 : (overlap + 4.0);
          double paddingRight = isLast ? 20.0 : (overlap + 4.0);

          // Icon (16) + Spacing (4)
          double contentBase = 16.0 + 4.0;

          // Measure Text
          final textPainter = TextPainter(
            text: TextSpan(
              text: seg.label,
              style: TextStyle(fontSize: fs, fontWeight: FontWeight.bold),
            ),
            textDirection: TextDirection.ltr,
            maxLines: 1,
          )..layout();

          return paddingLeft + contentBase + textPainter.width + paddingRight;
        }

        // 1. Determine Font Size
        while (fontSize >= minFontSize) {
          double totalSnugWidth = 0.0;
          snugMinimums.clear();
          for (var seg in segments) {
            double w = calculateSnugMinimum(seg, fontSize);
            snugMinimums[seg] = w;
            totalSnugWidth += w;
          }

          if (totalSnugWidth <= effectiveWidth) {
            break; // Fits!
          }
          fontSize -= 1.0;
        }

        // 2. Proportional Distribution
        Map<Segment, double> segmentWidths = {};

        // Handle edge case where totalTime is 0 or missing
        // Use totalTime prop as authoritative if > 0, else sum segments
        double totalTimeVal = totalTime;
        if (totalTimeVal <= 0) {
          totalTimeVal = segments.fold(0.0, (sum, s) => sum + s.time);
          if (totalTimeVal <= 0) {
            totalTimeVal = segments.length.toDouble(); // Fallback
          }
        }

        Set<Segment> fixedSegments = {};
        Set<Segment> flexibleSegments = segments.toSet();

        // Initialize widths
        for (var seg in segments) {
          segmentWidths[seg] = 0.0;
        }

        // Iterative distribution loop
        while (flexibleSegments.isNotEmpty) {
          // Calculate remaining available width
          double fixedWidthSum = fixedSegments.fold(
            0.0,
            (sum, s) => sum + segmentWidths[s]!,
          );
          double availableForFlexible = effectiveWidth - fixedWidthSum;

          // Calculate total time of flexible segments
          // If totalTime was provided, we assume segments are proportional to it.
          // Wait, if we use totalTimeVal from prop, but we only sum flexible segments' times,
          // we are effectively renormalizing the flexible segments to fit the available space.
          // This is what we want: "Re-distribution: ... subtract that stolen width from the larger segments".
          double flexibleTimeSum = flexibleSegments.fold(
            0.0,
            (sum, s) => sum + (totalTime > 0 ? s.time : 1),
          );

          List<Segment> newlyFixed = [];

          // If flexibleTimeSum is 0 (all remaining flexible segments have 0 time), distribute equally
          if (flexibleTimeSum <= 0) {
            double equalShare = availableForFlexible / flexibleSegments.length;
            for (var seg in flexibleSegments) {
              double minW = snugMinimums[seg]!;
              if (equalShare < minW) {
                segmentWidths[seg] = minW;
                newlyFixed.add(seg);
              } else {
                segmentWidths[seg] = equalShare;
              }
            }
          } else {
            // Distribute proportionally
            for (var seg in flexibleSegments) {
              double segTime = (totalTime > 0 ? seg.time.toDouble() : 1.0);
              double share = (segTime / flexibleTimeSum) * availableForFlexible;
              double minW = snugMinimums[seg]!;

              if (share < minW) {
                segmentWidths[seg] = minW;
                newlyFixed.add(seg);
              } else {
                segmentWidths[seg] = share;
              }
            }
          }

          if (newlyFixed.isEmpty) {
            break; // Stable
          }

          for (var s in newlyFixed) {
            fixedSegments.add(s);
            flexibleSegments.remove(s);
          }
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: segments.asMap().entries.map((entry) {
            final index = entry.key;
            final seg = entry.value;
            final isFirst = index == 0;
            final isLast = index == segments.length - 1;

            double width = segmentWidths[seg] ?? snugMinimums[seg] ?? 75.0;

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
                overlap: 12.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_getIconData(seg.iconId), color: textColor, size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        seg.label,
                        maxLines: 1,
                        // overflow: TextOverflow.ellipsis, // REMOVED
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
          left: isFirst ? 20 : (overlap + 4),
          right: isLast ? 20 : (overlap + 4),
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
    final r = 10.0; // Fixed radius for rounded rectangle ends

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
