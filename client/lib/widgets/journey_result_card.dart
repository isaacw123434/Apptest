import 'package:flutter/material.dart';
import '../models.dart';
import '../utils/app_colors.dart';
import '../utils/journey_utils.dart';
import '../screens/detail_page.dart';
import 'timeline_summary_view.dart';
import 'journey_result/journey_result_header.dart';
import 'journey_result/journey_badges.dart';

class JourneyResultCard extends StatelessWidget {
  final JourneyResult result;
  final bool isTopChoice;
  final bool isLeastRisky;
  final String? routeId;
  final Leg? mainLeg;
  final Map<String, bool> selectedModes;
  final int minCompressionLevel;

  const JourneyResultCard({
    super.key,
    required this.result,
    required this.isTopChoice,
    required this.isLeastRisky,
    this.routeId,
    this.mainLeg,
    required this.selectedModes,
    this.minCompressionLevel = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailPage(
              journeyResult: result,
              routeId: routeId,
              selectedModes: selectedModes,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.slate200),
          boxShadow: const [
            BoxShadow(
              color: Colors.white,
              offset: Offset(0, -1),
              blurRadius: 0,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black12,
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  JourneyResultHeader(result: result),
                  const SizedBox(height: 16),
                  _buildSchematic(result),
                  const SizedBox(height: 16),
                  JourneyBadges(
                    result: result,
                    isLeastRisky: isLeastRisky,
                    mainLeg: mainLeg,
                    routeId: routeId,
                  ),
                ],
              ),
            ),
            if (isTopChoice)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 4),
                color: const Color(0xFFECFDF5), // Emerald 50
                child: const Text(
                  'TOP CHOICE',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF047857), // Emerald 700
                    letterSpacing: 1.0,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSchematic(JourneyResult result) {
    List<Segment> processedSegments = collectSchematicSegments(result, mainLeg);

    double totalTime = result.time.toDouble();
    if (totalTime == 0) totalTime = 1;

    return TimelineSummaryView(
      segments: processedSegments,
      totalTime: totalTime,
      minCompressionLevel: minCompressionLevel,
    );
  }
}
