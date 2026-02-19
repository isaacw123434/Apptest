import 'package:flutter/material.dart';
import '../models.dart';
import '../utils/time_utils.dart';
import '../utils/icon_utils.dart';

const Map<String, String> trainLogos = {
  'Northern': 'assets/Northern_Logo.jpeg',
  'CrossCountry': 'assets/CrossCountry_Logo.png',
  'EMR': 'assets/EMR_Logo.png',
  'Transpennine Express': 'assets/Transpennine_Logo.png',
};

const double logoWidth = 50.0;

class TimelineSummaryView extends StatelessWidget {
  final List<Segment> segments;
  final double totalTime;
  final int minCompressionLevel;

  const TimelineSummaryView({
    super.key,
    required this.segments,
    required this.totalTime,
    this.minCompressionLevel = 0,
  });

  static final List<CompressionConfig> levels = [
    const CompressionConfig(), // Level 0: Standard
    const CompressionConfig(simplifyBus: true), // Level 1
    const CompressionConfig(simplifyBus: true, simplifyTrain: true), // Level 2
    const CompressionConfig(simplifyBus: true, simplifyTrain: true, compactWalk: true), // Level 3
    const CompressionConfig(simplifyBus: true, simplifyTrain: true, compactWalk: true, smallWalkIcon: true), // Level 4
  ];

  static int calculateRequiredLevel(List<Segment> segments, double availableWidth, TextScaler textScaler) {
    const double overlap = 10.0;
    // Assume 1000 if infinite, similar to build method logic, though caller should provide valid width
    final double effectiveWidth = availableWidth.isFinite ? availableWidth : 1000.0;

    for (int i = 0; i < levels.length; i++) {
      final config = levels[i];
      final result = _calculateLayout(segments, textScaler, config, overlap);
      if (result.totalMinWidth <= effectiveWidth) {
        return i;
      }
    }
    return levels.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final TextScaler textScaler = MediaQuery.of(context).textScaler;
        final availableWidth = constraints.maxWidth;
        final double effectiveWidth = availableWidth.isFinite
            ? availableWidth
            : 1000.0;

        const double fontSize = 12.0;
        const double durationFontSize = 10.0;
        const double overlap = 10.0;

        CompressionConfig selectedConfig = levels[0];
        _LayoutResult layoutResult = _calculateLayout(segments, textScaler, selectedConfig, overlap);

        // Start checking from minCompressionLevel
        int startLevel = minCompressionLevel;
        if (startLevel >= levels.length) startLevel = levels.length - 1;

        bool fits = false;

        // Try finding a level that fits, starting from startLevel
        for (int i = startLevel; i < levels.length; i++) {
           final config = levels[i];
           final result = _calculateLayout(segments, textScaler, config, overlap);
           if (result.totalMinWidth <= effectiveWidth) {
             selectedConfig = config;
             layoutResult = result;
             fits = true;
             break;
           }
        }

        // If still doesn't fit, use the most compact one
        if (!fits) {
           selectedConfig = levels.last;
           layoutResult = _calculateLayout(segments, textScaler, selectedConfig, overlap);
        }

        bool scrollNeeded = layoutResult.totalMinWidth > effectiveWidth;
        List<double> segmentWidths = List.filled(segments.length, 0.0);

        if (scrollNeeded) {
          // Use minWidth for every segment
          for (int i = 0; i < segments.length; i++) {
            segmentWidths[i] = layoutResult.minWidths[i];
          }
        } else {
          // Distribute Bonus Space
          double bonusSpace = effectiveWidth - layoutResult.totalMinWidth;

          // Calculate sum of time for segments to distribute bonus proportionally
          double timeSum = segments.fold(0.0, (sum, s) => sum + s.time);
          if (timeSum <= 0) timeSum = 1.0; // Avoid division by zero

          for (int i = 0; i < segments.length; i++) {
            final seg = segments[i];
            double proportion = seg.time / timeSum;
            double share = proportion * bonusSpace;
            segmentWidths[i] = layoutResult.minWidths[i] + share;
          }
        }

        Widget content = IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: segments.asMap().entries.map((entry) {
              return _buildSegmentWidget(
                entry.key,
                entry.value,
                segmentWidths[entry.key],
                fontSize,
                durationFontSize,
                overlap,
                selectedConfig,
              );
            }).toList(),
          ),
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

  Widget _buildSegmentWidget(
    int index,
    Segment seg,
    double width,
    double fontSize,
    double durationFontSize,
    double overlap,
    CompressionConfig config,
  ) {
    final isFirst = index == 0;
    final isLast = index == segments.length - 1;

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

    String displayText = _getDisplayText(seg, config);
    bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.label.toLowerCase() == 'walk';

    IconData? iconData = getIconData(seg.iconId);

    String durationText = formatDuration(seg.time, compact: isWalk);
    double iconSize = (isWalk && config.smallWalkIcon) ? 12.0 : 16.0;

    List<String> labelParts = seg.label.split(' + ');
    bool useLogo = false;

    if (config.simplifyTrain && seg.mode.toLowerCase() == 'train') {
       for (var part in labelParts) {
         if (trainLogos.containsKey(part)) {
           useLogo = true;
           break;
         }
       }
    }

    return SizedBox(
      width: width,
      child: HorizontalJigsawSegment(
        isFirst: isFirst,
        isLast: isLast,
        backgroundColor: color,
        borderColor: Colors.white,
        overlap: overlap,
        compactPadding: isWalk && config.compactWalk,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 8), // Add some vertical padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (useLogo) ...[
                    // Add Lucide train icon always if logos are used, as requested.
                    // "even with the train brand logos we still need the lucidide train logo"
                    if (iconData != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 4.0),
                        child: Icon(iconData, color: textColor, size: iconSize),
                      ),

                    for (int k = 0; k < labelParts.length; k++) ...[
                      if (k > 0) ...[
                        const SizedBox(width: 2),
                        Icon(Icons.add, color: textColor, size: 10),
                        const SizedBox(width: 2),
                      ],
                      if (trainLogos.containsKey(labelParts[k]))
                        Builder(builder: (context) {
                          double w = (labelParts[k] == 'EMR') ? logoWidth : 20.0;
                          Widget img = Image.asset(
                            trainLogos[labelParts[k]]!,
                            height: 20,
                            width: w,
                            fit: BoxFit.contain,
                          );
                          if (labelParts[k] == 'EMR') {
                            // EMR: White background + circular cutout (ClipOval on Container)
                            return ClipOval(
                              child: Container(
                                color: Colors.white,
                                height: 20,
                                width: w, // 50.0 for EMR
                                alignment: Alignment.center,
                                child: img,
                              ),
                            );
                          } else {
                            // Others: Circular cutout
                            return ClipOval(child: img);
                          }
                        })
                      else
                        Flexible(
                          child: Text(
                            labelParts[k],
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: TextStyle(
                              color: textColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ]
                  ] else ...[
                    if (iconData != null)
                      Icon(iconData, color: textColor, size: iconSize),
                    if (displayText.isNotEmpty) ...[
                      if (iconData != null) const SizedBox(width: 2),
                      Flexible(
                        child: Text(
                          displayText,
                          maxLines: 1,
                          softWrap: false,
                          overflow: TextOverflow.visible,
                          style: TextStyle(
                            color: textColor,
                            fontSize: fontSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ]
                ],
              ),
              Text(
                durationText,
                maxLines: 1,
                style: TextStyle(
                  color: textColor,
                  fontSize: durationFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class HorizontalJigsawSegment extends StatelessWidget {
  final Widget child;
  final bool isFirst;
  final bool isLast;
  final Color backgroundColor;
  final Color borderColor;
  final double overlap;
  final bool compactPadding;

  const HorizontalJigsawSegment({
    super.key,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.backgroundColor = Colors.blue,
    this.borderColor = Colors.white,
    this.overlap = 10.0,
    this.compactPadding = false,
  });

  @override
  Widget build(BuildContext context) {
    // Standard left padding calculation
    // If compactPadding is true, we reduce the padding slightly
    double leftP = isFirst ? 6 : (overlap + 1.0) * 0.75;
    double rightP = isLast ? 6.0 : 4.0;

    if (compactPadding) {
      // Reduce padding if compact is requested (mainly for walks)
      if (isFirst) {
        leftP = 2.0;
      } else {
        leftP = (overlap + 1.0) * 0.5; // Tighter overlap padding
      }

      if (isLast) {
        rightP = 2.0;
      } else {
        rightP = 1.0;
      }
    }

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
          left: leftP,
          right: rightP,
          top: 1,
          bottom: 1,
        ),
        child: child,
      ),
    );
  }
}

class CompressionConfig {
  final bool simplifyBus;
  final bool simplifyTrain;
  final bool compactWalk;
  final bool smallWalkIcon;

  const CompressionConfig({
    this.simplifyBus = false,
    this.simplifyTrain = false,
    this.compactWalk = false,
    this.smallWalkIcon = false,
  });
}

class _LayoutResult {
  final List<double> minWidths;
  final double totalMinWidth;

  _LayoutResult(this.minWidths, this.totalMinWidth);
}

String _getDisplayText(Segment seg, CompressionConfig config) {
  String displayText = seg.label;
  bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.label.toLowerCase() == 'walk';

  if (isWalk) {
    return '';
  }

  if (config.simplifyBus &&
      seg.mode.toLowerCase() == 'bus' &&
      displayText.toLowerCase().startsWith('bus ')) {
    return displayText.substring(4).trim();
  }
  if (config.simplifyTrain && seg.mode.toLowerCase() == 'train') {
    return 'Train';
  }

  return displayText;
}

_LayoutResult _calculateLayout(
  List<Segment> segments,
  TextScaler textScaler,
  CompressionConfig config,
  double overlap,
) {
  const double fontSize = 12.0;
  const double durationFontSize = 10.0;

  List<double> minWidths = List.filled(segments.length, 0.0);
  double totalMinWidth = 0.0;

  for (int i = 0; i < segments.length; i++) {
    final seg = segments[i];
    bool isFirst = i == 0;
    bool isLast = i == segments.length - 1;

    // Determine padding based on compactWalk config
    double paddingLeft;
    double paddingRight;

    bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.label.toLowerCase() == 'walk';
    bool applyCompact = isWalk && config.compactWalk;

    if (applyCompact) {
      if (isFirst) {
        paddingLeft = 2.0;
      } else {
        paddingLeft = (overlap + 1.0) * 0.5;
      }

      if (isLast) {
        paddingRight = 2.0;
      } else {
        paddingRight = 1.0;
      }
    } else {
      paddingLeft = isFirst ? 6.0 : (overlap + 1.0) * 0.75;
      paddingRight = isLast ? 6.0 : 4.0;
    }

    List<String> labelParts = seg.label.split(' + ');
    bool useLogo = false;

    if (config.simplifyTrain && seg.mode.toLowerCase() == 'train') {
       for (var part in labelParts) {
         if (trainLogos.containsKey(part)) {
           useLogo = true;
           break;
         }
       }
    }

    IconData? iconData = getIconData(seg.iconId);
    bool hasIcon = iconData != null;
    double iconSize = (isWalk && config.smallWalkIcon) ? 12.0 : 16.0;

    // Icon + Spacing (2)
    double contentBase = hasIcon ? (iconSize + 2.0) : 0.0;

    String displayText = _getDisplayText(seg, config);

    if (isWalk) {
      contentBase = hasIcon ? iconSize : 0.0;
    } else if (useLogo) {
      contentBase = 0.0;
      displayText = '';

      // Calculate width with extra icon
      if (hasIcon) {
        contentBase += iconSize + 4.0;
      }

      for (int k = 0; k < labelParts.length; k++) {
        String part = labelParts[k];
        if (k > 0) {
           // Spacer (2) + Icon(+) (10) + Spacer (2) = 14.0
           contentBase += 14.0;
        }

        if (trainLogos.containsKey(part)) {
          double w = (part == 'EMR') ? logoWidth : 20.0;
          contentBase += w;
        } else {
           // Measure text for this part
           final partPainter = TextPainter(
              text: TextSpan(
                text: part,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              textDirection: TextDirection.ltr,
              textScaler: textScaler,
              maxLines: 1,
            )..layout();
            contentBase += partPainter.width;
        }
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: displayText,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    String durationText = formatDuration(seg.time, compact: isWalk);

    final durationPainter = TextPainter(
      text: TextSpan(
        text: durationText,
        style: TextStyle(
          fontSize: durationFontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
      maxLines: 1,
    )..layout();

    double topContentWidth =
        contentBase + (displayText.isNotEmpty ? textPainter.width : 0);
    double bottomContentWidth = durationPainter.width;
    double maxContentWidth = topContentWidth > bottomContentWidth
        ? topContentWidth
        : bottomContentWidth;

    double minW = (paddingLeft + maxContentWidth + paddingRight + 0.5)
            .ceilToDouble() +
        4.0;

    if (isWalk) {
      minW -= 4.0;
    }

    minWidths[i] = minW;
    totalMinWidth += minW;
  }

  return _LayoutResult(minWidths, totalMinWidth);
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
  bool shouldRepaint(covariant _HorizontalJigsawPainter oldDelegate) {
    return isFirst != oldDelegate.isFirst ||
        isLast != oldDelegate.isLast ||
        backgroundColor != oldDelegate.backgroundColor ||
        borderColor != oldDelegate.borderColor ||
        overlap != oldDelegate.overlap;
  }
}
