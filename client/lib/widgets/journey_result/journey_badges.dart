import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models.dart';
import '../../utils/app_colors.dart';
import '../info_badge.dart';
import 'risk_assessment_dialog.dart';

class JourneyBadges extends StatelessWidget {
  final JourneyResult result;
  final bool isLeastRisky;
  final Leg? mainLeg;
  final String? routeId;

  const JourneyBadges({
    super.key,
    required this.result,
    required this.isLeastRisky,
    this.mainLeg,
    this.routeId,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (isLeastRisky)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (context) => RiskAssessmentDialog(
                result: result,
                mainLeg: mainLeg,
                routeId: routeId,
              ),
            ),
            child: InfoBadge(
              text: 'Least Risky',
              icon: LucideIcons.shield,
              backgroundColor: AppColors.blue50,
              borderColor: Color(0xFFDBEAFE), // Blue 100
              iconColor: Color(0xFF1D4ED8),
              textColor: Color(0xFF1D4ED8),
              margin: EdgeInsets.only(right: 8),
            ),
          ),
        if (result.emissions.text != null)
          InfoBadge(
            text: result.emissions.text!,
            icon: LucideIcons.leaf,
            backgroundColor: const Color(0xFFECFDF5), // Emerald 50
            borderColor: const Color(0xFFD1FAE5), // Emerald 100
            iconColor: const Color(0xFF047857),
            textColor: const Color(0xFF047857),
          ),
      ],
    );
  }
}
