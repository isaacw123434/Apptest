import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../utils/app_colors.dart';

class SearchForm extends StatefulWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController timeController;
  final String timeType;
  final ValueChanged<String?> onTimeTypeChanged;
  final Map<String, bool> selectedModes;
  final Function(String, bool) onModeChanged;
  final List<Widget>? actions;

  const SearchForm({
    super.key,
    required this.fromController,
    required this.toController,
    required this.timeController,
    required this.timeType,
    required this.onTimeTypeChanged,
    required this.selectedModes,
    required this.onModeChanged,
    this.actions,
  });

  @override
  State<SearchForm> createState() => _SearchFormState();
}

class _SearchFormState extends State<SearchForm> {
  bool _isModeDropdownOpen = false;

  final List<Map<String, dynamic>> _modeOptions = [
    {'id': 'train', 'icon': LucideIcons.train, 'label': 'Train'},
    {'id': 'bus', 'icon': LucideIcons.bus, 'label': 'Bus'},
    {'id': 'car', 'icon': LucideIcons.car, 'label': 'Car'},
    {'id': 'taxi', 'icon': LucideIcons.car, 'label': 'Taxi'},
    {'id': 'bike', 'icon': LucideIcons.bike, 'label': 'Bike'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInputRow(LucideIcons.circle, widget.fromController, Colors.grey, 'Start'),
        const SizedBox(height: 12),
        _buildInputRow(LucideIcons.circle, widget.toController, Colors.black, 'End'),
        const SizedBox(height: 12),
        _buildTimeRow(),
        const SizedBox(height: 12),
        if (widget.actions != null) ...[
          ...widget.actions!,
          const SizedBox(height: 12),
        ],
        _buildModeFilter(),
      ],
    );
  }

  Widget _buildInputRow(IconData icon, TextEditingController controller, Color dotColor, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Optional: Label could be added here if needed, consistent with SummaryPage
        // Text(label, style: ...),
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

  Widget _buildModeFilter() {
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
