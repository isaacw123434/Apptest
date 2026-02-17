import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../utils/app_colors.dart';
import '../utils/journey_utils.dart';
import '../utils/risk_helper.dart';
import '../utils/time_utils.dart';
import '../screens/detail_page.dart';
import '../screens/horizontal_jigsaw_schematic.dart';

class JourneyResultCard extends StatelessWidget {
  final JourneyResult result;
  final bool isTopChoice;
  final bool isLeastRisky;
  final String? routeId;
  final Leg? mainLeg;
  final Map<String, bool> selectedModes;

  const JourneyResultCard({
    super.key,
    required this.result,
    required this.isTopChoice,
    required this.isLeastRisky,
    this.routeId,
    this.mainLeg,
    required this.selectedModes,
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '£${result.cost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          if (result.anchor.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Via ${result.anchor}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.slate500,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            formatDuration(result.time),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                          ),
                          Builder(builder: (context) {
                            final times = calculateJourneyTimes(result);
                            return Text(
                              '${formatTime(times['start']!)} - ${formatTime(times['end']!)}',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate500),
                            );
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Schematic
                  SizedBox(
                    height: 45,
                    child: _buildSchematic(result),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (isLeastRisky)
                        GestureDetector(
                          onTap: () => _showRiskDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: AppColors.blue50,
                              border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 100
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: const [
                                Icon(LucideIcons.shield, size: 12, color: Color(0xFF1D4ED8)),
                                SizedBox(width: 4),
                                Text(
                                  'Least Risky',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (result.emissions.text != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5), // Emerald 50
                            border: Border.all(color: const Color(0xFFD1FAE5)), // Emerald 100
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              const Icon(LucideIcons.leaf, size: 12, color: Color(0xFF047857)),
                              const SizedBox(width: 4),
                              Text(
                                result.emissions.text!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
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
                    fontSize: 10,
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
    List<Segment> processedSegments = [];
    processedSegments.addAll(processSegments(result.leg1.segments));

    if (mainLeg != null) {
      processedSegments.addAll(processSegments(mainLeg!.segments));
    } else {
      processedSegments.addAll(processSegments([
        Segment(
          mode: 'train',
          label: 'CrossCountry',
          lineColor: '#713e8d',
          iconId: 'train',
          time: 102,
        )
      ]));
    }

    processedSegments.addAll(processSegments(result.leg3.segments));

    double totalTime = result.time.toDouble();
    if (totalTime == 0) totalTime = 1;

    return HorizontalJigsawSchematic(
      segments: processedSegments,
      totalTime: totalTime,
    );
  }

  void _showRiskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blue50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.shield, color: AppColors.brand),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Risk Assessment',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'This journey has the lowest risk score.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.slate200),
                ),
                child: Builder(builder: (context) {
                  final breakdown = calculateRiskBreakdown(result, mainLeg, routeId);
                  return Column(
                    children: [
                      _buildRiskRow('First Mile', null,
                          scoreOverride: breakdown.firstMileScore, reasonOverride: breakdown.firstMileReason),
                      const SizedBox(height: 12),
                      _buildRiskRow('Main Leg', null,
                          scoreOverride: breakdown.mainLegScore, reasonOverride: breakdown.mainLegReason),
                      const SizedBox(height: 12),
                      _buildRiskRow('Last Mile', null,
                          scoreOverride: breakdown.lastMileScore, reasonOverride: breakdown.lastMileReason),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Score', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(result.risk.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
                        ],
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 16),
              const Text(
                'Calculated based on historical delay data, number of transfers, and connection buffer times.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiskRow(String title, Leg? leg, {int? scoreOverride, String? reasonOverride}) {
    final score = scoreOverride ?? leg?.riskScore ?? 0;
    final reason = reasonOverride ?? leg?.riskReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: AppColors.slate500)),
            Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.slate500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
