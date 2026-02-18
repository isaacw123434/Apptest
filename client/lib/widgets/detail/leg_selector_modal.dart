import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../models.dart';
import '../../utils/time_utils.dart';
import '../../utils/icon_utils.dart';

class LegSelectorModal extends StatefulWidget {
  final List<Leg> options;
  final Leg currentLeg;
  final String title;
  final Function(Leg) onSelect;
  final String Function(Leg)? labelBuilder;

  const LegSelectorModal({
    super.key,
    required this.options,
    required this.currentLeg,
    required this.title,
    required this.onSelect,
    this.labelBuilder,
  });

  @override
  State<LegSelectorModal> createState() => _LegSelectorModalState();
}

class _LegSelectorModalState extends State<LegSelectorModal> {
  String _sortOption = 'Best Value';

  List<Leg> _getSortedOptions() {
    List<Leg> displayOptions = List.from(widget.options);

    displayOptions.sort((a, b) {
      if (_sortOption == 'Lowest Cost') {
        return a.cost.compareTo(b.cost);
      } else if (_sortOption == 'Lowest Time') {
        return a.time.compareTo(b.time);
      } else {
         double scoreA = a.cost + (a.time * 0.15);
         double scoreB = b.cost + (b.time * 0.15);
         return scoreA.compareTo(scoreB);
      }
    });

    return displayOptions;
  }


  @override
  Widget build(BuildContext context) {
      final sortedOptions = _getSortedOptions();

      return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                            value: _sortOption,
                            items: const [
                                DropdownMenuItem(value: 'Best Value', child: Text('Best Value')),
                                DropdownMenuItem(value: 'Lowest Cost', child: Text('Lowest Cost')),
                                DropdownMenuItem(value: 'Lowest Time', child: Text('Lowest Time')),
                            ],
                            onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                            },
                            underline: Container(),
                            icon: const Icon(LucideIcons.arrowUpDown, size: 16),
                        ),
                    ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = sortedOptions[index];
                    final isSelected = option.id == widget.currentLeg.id;

                    double priceDiff = option.cost - widget.currentLeg.cost;
                    int timeDiff = option.time - widget.currentLeg.time;

                    return GestureDetector(
                      onTap: () => widget.onSelect(option),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                          border: Border.all(
                            color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(getIconData(option.iconId) ?? LucideIcons.circle, size: 24, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.labelBuilder != null ? widget.labelBuilder!(option) : option.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    option.detail ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  children: [
                                    if (!isSelected && priceDiff != 0)
                                      Icon(
                                        priceDiff > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                        size: 12,
                                        color: priceDiff > 0 ? Colors.red : Colors.green,
                                      ),
                                    Text(
                                      isSelected
                                          ? '£${option.cost.toStringAsFixed(2)}'
                                          : (priceDiff > 0 ? '+£${priceDiff.abs().toStringAsFixed(2)}' : '-£${priceDiff.abs().toStringAsFixed(2)}'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? Colors.black : (priceDiff > 0 ? Colors.red : Colors.green),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (!isSelected && timeDiff != 0)
                                      Icon(
                                        timeDiff > 0 ? LucideIcons.arrowUp : LucideIcons.arrowDown,
                                        size: 12,
                                        color: timeDiff > 0 ? Colors.red : Colors.green,
                                      ),
                                    Text(
                                      isSelected
                                          ? formatDuration(option.time)
                                          : (timeDiff > 0 ? '+${formatDuration(timeDiff.abs())}' : '-${formatDuration(timeDiff.abs())}'),
                                      style: TextStyle(
                                        color: isSelected ? Colors.grey : (timeDiff > 0 ? Colors.red : Colors.green),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
  }
}
