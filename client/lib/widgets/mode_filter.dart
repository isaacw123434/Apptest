import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_colors.dart';

class ModeFilter extends StatefulWidget {
  final Map<String, bool> selectedModes;
  final Function(String, bool) onModeChanged;

  const ModeFilter({
    super.key,
    required this.selectedModes,
    required this.onModeChanged,
  });

  @override
  State<ModeFilter> createState() => _ModeFilterState();
}

class _ModeFilterState extends State<ModeFilter> {
  bool _isModeDropdownOpen = false;

  static const List<Map<String, dynamic>> _modeOptions = [
    {'id': 'train', 'icon': LucideIcons.train, 'label': 'Train'},
    {'id': 'bus', 'icon': LucideIcons.bus, 'label': 'Bus'},
    {'id': 'car', 'icon': LucideIcons.car, 'label': 'Car'},
    {'id': 'taxi', 'icon': LucideIcons.car, 'label': 'Taxi'},
    {'id': 'bike', 'icon': LucideIcons.bike, 'label': 'Bike'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isModeDropdownOpen = !_isModeDropdownOpen;
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Modes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                  ),
                ),
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: AppColors.slate500,
                ),
              ],
            ),
          ),
        ),
        if (_isModeDropdownOpen) ...[
          const SizedBox(height: 8),
          Row(
            children: _modeOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final mode = entry.value;
              final isSelected = widget.selectedModes[mode['id']] ?? false;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == _modeOptions.length - 1 ? 0 : 8.0),
                  child: InkWell(
                    onTap: () => widget.onModeChanged(mode['id'], !isSelected),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.blue50 : Colors.white,
                        border: Border.all(
                          color: isSelected ? AppColors.brand : AppColors.slate200,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            mode['icon'],
                            size: 20,
                            color: isSelected ? AppColors.brand : AppColors.slate400,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mode['label'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
