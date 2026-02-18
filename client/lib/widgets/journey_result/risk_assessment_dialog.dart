import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models.dart';
import '../../utils/app_colors.dart';
import '../../utils/risk_helper.dart';

class RiskAssessmentDialog extends StatelessWidget {
  final JourneyResult result;
  final Leg? mainLeg;
  final String? routeId;

  const RiskAssessmentDialog({
    super.key,
    required this.result,
    this.mainLeg,
    this.routeId,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  child: Icon(LucideIcons.shield, color: AppColors.brand),
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
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brand)),
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
            Text(title, style: TextStyle(color: AppColors.slate500)),
            Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              reason,
              style: TextStyle(
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
