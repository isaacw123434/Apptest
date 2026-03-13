import 'package:flutter/material.dart';
import '../../models.dart';
import '../../screens/direct_drive_page.dart';
import '../../utils/time_utils.dart';

class DrivingBaselineCard extends StatelessWidget {
  final DirectDrive directDrive;
  final String? routeId;

  const DrivingBaselineCard({
    super.key,
    required this.directDrive,
    this.routeId,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectDrivePage(
              routeId: routeId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFFFEFCE8), // Amber 50 — warm tint to distinguish
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFFDE68A), // Amber 200 dashed-feel border
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Driving baseline" label strip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF3C7), // Amber 100
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.compare_arrows, size: 14, color: Color(0xFF92400E)), // Amber 800
                  SizedBox(width: 6),
                  Text(
                    'Driving Baseline',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF92400E), // Amber 800
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE68A), // Amber 200
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.directions_car, size: 20, color: Color(0xFF78350F)), // Amber 900
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Drive Only',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Color(0xFF78350F), // Amber 900
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Tap to compare with alternatives',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFFB45309), // Amber 700
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '£${directDrive.cost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF78350F), // Amber 900
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDuration(directDrive.time),
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                          color: Color(0xFFB45309), // Amber 700
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Color(0xFFD97706), // Amber 600
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
