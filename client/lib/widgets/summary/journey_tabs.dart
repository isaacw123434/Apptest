import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../utils/app_colors.dart';

class JourneyTabs extends StatelessWidget {
  final String activeTab;
  final ValueChanged<String> onTabChanged;

  const JourneyTabs({
    super.key,
    required this.activeTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTab('fastest', 'Fastest', LucideIcons.zap),
          _buildTab('smart', 'Best Value', LucideIcons.shieldCheck),
          _buildTab('cheapest', 'Cheapest', LucideIcons.leaf),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final isActive = activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => onTabChanged(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.brand : Colors.transparent,
                width: 2,
              ),
            ),
            color: isActive ? AppColors.brandLight.withAlpha(77) : null, // 0.3 * 255 = 76.5
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? AppColors.brand : AppColors.slate400,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? AppColors.brand : AppColors.slate400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
