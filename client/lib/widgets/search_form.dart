import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_colors.dart';
import 'mode_filter.dart';

class SearchForm extends StatefulWidget {
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
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputRow(LucideIcons.circle, widget.fromController, Colors.grey),
        const SizedBox(height: 12),
        _buildInputRow(LucideIcons.circle, widget.toController, Colors.black),
        const SizedBox(height: 12),
        _buildTimeRow(),
        const SizedBox(height: 12),
        ModeFilter(
          selectedModes: widget.selectedModes,
          onModeChanged: widget.onModeChanged,
        ),
      ],
    );
  }

  Widget _buildInputRow(IconData icon, TextEditingController controller, Color dotColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
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
        ),
      ],
    );
  }

  Widget _buildTimeRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                DropdownButton<String>(
                  value: widget.timeType,
                  underline: Container(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.slate500,
                  ),
                  icon: const Icon(LucideIcons.chevronDown, size: 14, color: AppColors.slate400),
                  onChanged: widget.onTimeTypeChanged,
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
                    controller: widget.timeController,
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
          ),
        ),
      ],
    );
  }
}
