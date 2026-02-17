import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0), // Slate 200
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.car, size: 20, color: Color(0xFF475569)), // Slate 600
                ),
                const SizedBox(width: 12),
                const Text(
                  'Driving',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF334155), // Slate 700
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '£${directDrive.cost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626), // Red 600
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(directDrive.time),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF64748B), // Slate 500
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
