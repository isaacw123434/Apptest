import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models.dart';
import '../../providers/saved_routes_provider.dart';
import '../../screens/saved_routes_page.dart';
import '../../utils/app_colors.dart';

class SavedRoutesSection extends StatelessWidget {
  const SavedRoutesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedRoutesProvider>(
      builder: (context, provider, _) {
        final routes = provider.savedRoutes;
        if (routes.isEmpty) return const SizedBox.shrink();

        // Group by routeKey
        final grouped = <String, List<SavedRoute>>{};
        for (final r in routes) {
          grouped.putIfAbsent(r.routeKey, () => []).add(r);
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Favourite Routes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.slate800,
                ),
              ),
              const SizedBox(height: 8),
              ...grouped.entries.map((entry) {
                final pair = entry.value.first;
                final count = entry.value.length;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SavedRoutesPage(
                          from: pair.from,
                          to: pair.to,
                          selectedModes: const {
                            'train': true,
                            'bus': true,
                            'car': true,
                            'taxi': true,
                            'bike': true,
                          },
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
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
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.favorite,
                              size: 18, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${pair.from} → ${pair.to}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.slate700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$count favourite${count == 1 ? '' : 's'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: AppColors.slate400),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
