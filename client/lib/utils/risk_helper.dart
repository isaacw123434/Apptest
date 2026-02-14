import '../models.dart';

class RiskBreakdown {
  final int firstMileScore;
  final String? firstMileReason;
  final int mainLegScore;
  final String? mainLegReason;
  final int lastMileScore;
  final String? lastMileReason;
  final int totalScore;

  RiskBreakdown({
    required this.firstMileScore,
    this.firstMileReason,
    required this.mainLegScore,
    this.mainLegReason,
    required this.lastMileScore,
    this.lastMileReason,
    required this.totalScore,
  });
}

RiskBreakdown calculateRiskBreakdown(JourneyResult result, Leg? mainLeg, String? routeId) {
  int firstMileScore = result.leg1.riskScore;
  String? firstMileReason = result.leg1.riskReason;

  // Base main leg score (from the shared main leg definition)
  int mainLegScore = mainLeg?.riskScore ?? 0;
  String? mainLegReason = mainLeg?.riskReason;

  // Override main leg score based on total calculation logic in ApiService
  // result.risk = l1 + main + l3
  // So mainLeg effective score in result = result.risk - l1 - l3
  int effectiveMainLegScore = result.risk - firstMileScore - result.leg3.riskScore;

  // Use effective score if different (though for Route 2 mainLeg is 0)
  if (effectiveMainLegScore != mainLegScore) {
      mainLegScore = effectiveMainLegScore;
  }

  int lastMileScore = result.leg3.riskScore;
  String? lastMileReason = result.leg3.riskReason;

  // Fix for Route 2 Access Options (Integrated Train)
  // Check if first leg contains a train segment, indicating it's an integrated leg
  if (routeId == 'route2' && result.leg1.segments.any((s) => s.mode.toLowerCase() == 'train')) {
      if (firstMileReason != null) {
          if (firstMileReason == 'Connection risk') {
              // Move entirely to Main Leg
              firstMileScore = 0;
              firstMileReason = 'Most reliable';

              mainLegScore += 1;
              mainLegReason = _appendReason(mainLegReason, 'Connection risk');
          } else if (firstMileReason.contains(' + Connection risk (+1)')) {
              // Split: e.g. "Bus risk (+1) + Connection risk (+1)"
              firstMileScore -= 1;
              firstMileReason = firstMileReason.replaceAll(' + Connection risk (+1)', '');

              mainLegScore += 1;
              mainLegReason = _appendReason(mainLegReason, 'Connection risk');
          } else if (firstMileReason.contains('Timing risk (+1) + Connection risk (+1)')) {
               // Split Walk+Train
              firstMileScore -= 1;
              firstMileReason = firstMileReason.replaceAll(' + Connection risk (+1)', '');

              mainLegScore += 1;
              mainLegReason = _appendReason(mainLegReason, 'Connection risk');
          }
      }
  }

  return RiskBreakdown(
      firstMileScore: firstMileScore,
      firstMileReason: firstMileReason,
      mainLegScore: mainLegScore,
      mainLegReason: mainLegReason,
      lastMileScore: lastMileScore,
      lastMileReason: lastMileReason,
      totalScore: result.risk
  );
}

String? _appendReason(String? current, String addition) {
    if (current == null || current.isEmpty) return addition;
    if (current.contains(addition)) return current;
    return '$current, $addition';
}
