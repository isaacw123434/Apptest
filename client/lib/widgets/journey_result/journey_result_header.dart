import 'package:flutter/material.dart';
import '../../models.dart';
import '../../utils/app_colors.dart';
import '../../utils/time_utils.dart';
import '../../utils/journey_utils.dart';

class JourneyResultHeader extends StatelessWidget {
  final JourneyResult result;

  const JourneyResultHeader({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '£${result.cost.toStringAsFixed(2)}',
              style: TextStyle(
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
                  style: TextStyle(
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
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
            ),
            Builder(builder: (context) {
              final times = calculateJourneyTimes(result);
              return Text(
                '${formatTime(times['start']!)} - ${formatTime(times['end']!)}',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              );
            }),
          ],
        ),
      ],
    );
  }
}
