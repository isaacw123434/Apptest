import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_colors.dart';
import 'mode_filter.dart';

class SearchForm extends StatelessWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController timeController;
  final String timeType;
  final ValueChanged<String?> onTimeTypeChanged;
  final Map<String, bool> selectedModes;
  final Function(String, bool) onModeChanged;

  const SearchForm({
    super.key,
    required this.fromController,
    required this.toController,
    required this.timeController,
    required this.timeType,
    required this.onTimeTypeChanged,
    required this.selectedModes,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputRow(fromController, Colors.grey),
        const SizedBox(height: 12),
        _buildInputRow(toController, Colors.black),
        const SizedBox(height: 12),
        _buildTimeRow(),
        const SizedBox(height: 12),
        ModeFilter(
          selectedModes: selectedModes,
          onModeChanged: onModeChanged,
        ),
      ],
    );
  }

  Widget _buildInputRow(TextEditingController controller, Color dotColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true, // Assuming these are read-only for now as per original code
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.slate700,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.slate100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          DropdownButton<String>(
            value: timeType,
            underline: Container(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.slate500,
            ),
            icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.slate400),
            onChanged: onTimeTypeChanged,
            items: <String>['Depart', 'Arrive']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: timeController,
              readOnly: true,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.slate900,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
