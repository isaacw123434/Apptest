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
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        if (isLeastRisky)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (context) => RiskAssessmentDialog(
                result: result,
                isLeastRisky: isLeastRisky,
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
            ),
          ),
        if (!isLeastRisky && result.risk >= 4)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (context) => RiskAssessmentDialog(
                result: result,
                isLeastRisky: isLeastRisky,
                mainLeg: mainLeg,
                routeId: routeId,
              ),
            ),
            child: InfoBadge(
              text: 'High Risk',
              icon: LucideIcons.alertTriangle,
              backgroundColor: const Color(0xFFFEF2F2), // Red 50
              borderColor: const Color(0xFFFEE2E2), // Red 100
              iconColor: const Color(0xFFDC2626), // Red 600
              textColor: const Color(0xFFDC2626), // Red 600
            ),
          )
        else if (!isLeastRisky && result.risk >= 2)
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (context) => RiskAssessmentDialog(
                result: result,
                isLeastRisky: isLeastRisky,
                mainLeg: mainLeg,
                routeId: routeId,
              ),
            ),
            child: InfoBadge(
              text: 'Medium Risk',
              icon: LucideIcons.alertCircle,
              backgroundColor: const Color(0xFFFFFBEB), // Amber 50
              borderColor: const Color(0xFFFEF3C7), // Amber 100
              iconColor: const Color(0xFFD97706), // Amber 600
              textColor: const Color(0xFFD97706), // Amber 600
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
