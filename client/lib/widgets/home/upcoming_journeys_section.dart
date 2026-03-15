import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../providers/saved_routes_provider.dart';
import '../../utils/app_colors.dart';

class UpcomingJourneysSection extends StatelessWidget {
  const UpcomingJourneysSection({super.key});

  String _formatCountdown(DateTime savedAt) {
    final now = DateTime.now();
    final diff = savedAt.add(const Duration(days: 7)).difference(now);
    if (diff.isNegative) return 'Ready to go';
    if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} until journey';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours == 1 ? '' : 's'} until journey';
    }
    return 'Today';
  }

  IconData _iconForJourney(JourneyResult journey) {
    // Pick icon based on first segment mode
    final mode = journey.leg1.iconId;
    switch (mode) {
      case 'train':
        return Icons.train;
      case 'bus':
        return Icons.directions_bus;
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.pedal_bike;
      default:
        return Icons.directions_walk;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedRoutesProvider>(
      builder: (context, provider, _) {
        final upcoming = provider.upcomingRoutes;
        if (upcoming.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Upcoming Journeys',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 12),
              ...upcoming.map((saved) => Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.slate100),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 2,
                            offset: Offset(0, 1)),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brand,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _iconForJourney(saved.journey),
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${saved.from} → ${saved.to}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate800,
                                    ),
                                  ),
                                  Text(
                                    _formatCountdown(saved.savedAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.bookmark,
                                size: 20, color: AppColors.brand),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _InfoChip(
                              icon: Icons.access_time,
                              label:
                                  '${saved.journey.time} min',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.attach_money,
                              label:
                                  '£${saved.journey.cost.toStringAsFixed(2)}',
                            ),
                            const SizedBox(width: 8),
                            _InfoChip(
                              icon: Icons.eco,
                              label:
                                  '${saved.journey.emissions.val.toStringAsFixed(1)} kg',
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.slate400),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ],
      ),
    );
  }
}
