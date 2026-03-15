import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ModeFilter extends StatelessWidget {
  final Map<String, bool> selectedModes;
  final Function(String, bool) onModeChanged;

  const ModeFilter({
    super.key,
    required this.selectedModes,
    required this.onModeChanged,
  });

  static const List<Map<String, dynamic>> _modeOptions = [
    {'id': 'train', 'icon': Icons.train, 'label': 'Train'},
    {'id': 'bus', 'icon': Icons.directions_bus, 'label': 'Bus'},
    {'id': 'car', 'icon': Icons.directions_car, 'label': 'Car'},
    {'id': 'taxi', 'icon': Icons.local_taxi, 'label': 'Taxi'},
    {'id': 'bike', 'icon': Icons.pedal_bike, 'label': 'Bike'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Exclude Modes',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
        ),
        Row(
          children: _modeOptions.asMap().entries.map((entry) {
            final index = entry.key;
            final mode = entry.value;
            final isIncluded = selectedModes[mode['id']] ?? true;
            final isExcluded = !isIncluded;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index == _modeOptions.length - 1 ? 0 : 8.0),
                child: InkWell(
                  onTap: () => onModeChanged(mode['id'], !isIncluded),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isExcluded ? const Color(0xFFFEF2F2) : Colors.white,
                      border: Border.all(
                        color: isExcluded ? const Color(0xFFDC2626) : AppColors.slate200,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          mode['icon'],
                          size: 20,
                          color: isExcluded ? const Color(0xFFDC2626) : AppColors.slate400,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mode['label'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isExcluded ? const Color(0xFFDC2626) : null,
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
    );
  }
}
