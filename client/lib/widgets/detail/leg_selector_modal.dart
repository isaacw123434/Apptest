import 'package:flutter/material.dart';
import '../../models.dart';
import '../../utils/time_utils.dart';
import '../../utils/icon_utils.dart';

/// A group of legs that share a common route (e.g. all "via Brough" options).
class LegOptionGroup {
  final String title;
  final String? subtitle;
  final IconData icon;
  final List<Leg> options;

  LegOptionGroup({
    required this.title,
    this.subtitle,
    required this.icon,
    required this.options,
  });

  Leg get cheapest => options.reduce((a, b) => a.cost < b.cost ? a : b);
}

class LegSelectorModal extends StatefulWidget {
  final List<LegOptionGroup> groups;
  final Leg currentLeg;
  final String title;
  final Function(Leg) onSelect;

  const LegSelectorModal({
    super.key,
    required this.groups,
    required this.currentLeg,
    required this.title,
    required this.onSelect,
  });

  @override
  State<LegSelectorModal> createState() => _LegSelectorModalState();
}

class _LegSelectorModalState extends State<LegSelectorModal> {
  String? _expandedGroupTitle;

  @override
  void initState() {
    super.initState();
    // Auto-expand the group containing the current leg
    for (var group in widget.groups) {
      if (group.options.any((o) => o.id == widget.currentLeg.id)) {
        _expandedGroupTitle = group.title;
        break;
      }
    }
  }

  String _getAccessModeLabel(Leg leg) {
    final id = leg.id.toLowerCase();
    if (id.contains('walk')) return 'Walk';
    if (id.contains('cycle')) return 'Cycle';
    if (id.contains('uber')) return 'Uber';
    if (id.contains('drive_park')) return 'Park';
    if (id.contains('drive')) return 'Drive';
    if (id.contains('bus') && !id.contains('train')) return 'Bus';
    if (id.contains('taxi')) return 'Taxi';

    // Fallback: first non-walk/wait segment label
    for (var seg in leg.segments) {
      if (seg.mode == 'walk' || seg.mode == 'wait' || seg.iconId == 'footprints') continue;
      final word = seg.label.split(' ').first;
      return word.isNotEmpty ? word : leg.label.split(' ').first;
    }
    return leg.label.split(' ').first;
  }

  IconData _getAccessModeIcon(Leg leg) {
    final id = leg.id.toLowerCase();
    if (id.contains('walk')) return Icons.directions_walk;
    if (id.contains('cycle')) return Icons.pedal_bike;
    if (id.contains('uber') || id.contains('taxi')) return Icons.local_taxi;
    if (id.contains('drive')) return Icons.directions_car;
    if (id.contains('bus') && !id.contains('train')) return Icons.directions_bus;

    // Fallback: check first transport segment
    for (var seg in leg.segments) {
      if (seg.mode == 'walk' || seg.mode == 'wait') continue;
      return getIconData(seg.iconId) ?? Icons.circle;
    }
    return getIconData(leg.iconId) ?? Icons.circle;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 48,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.title,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          // Groups list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: widget.groups.length,
              separatorBuilder: (context, i) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final group = widget.groups[index];
                final isExpanded = _expandedGroupTitle == group.title;
                final isCurrentGroup = group.options.any((o) => o.id == widget.currentLeg.id);

                if (group.options.length == 1) {
                  return _buildSimpleCard(group.options.first, group, isCurrentGroup);
                }
                return _buildGroupCard(group, isExpanded, isCurrentGroup);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleCard(Leg option, LegOptionGroup group, bool isSelected) {
    final priceDiff = option.cost - widget.currentLeg.cost;
    final timeDiff = option.time - widget.currentLeg.time;

    return GestureDetector(
      onTap: () => widget.onSelect(option),
      child: Container(
        padding: const EdgeInsets.all(14),
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
              child: Icon(group.icon, size: 22, color: Colors.black87),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (group.subtitle != null)
                    Text(group.subtitle!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '£${option.cost.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (!isSelected && priceDiff != 0)
                  _buildDiffChip(priceDiff, isPrice: true),
                const SizedBox(height: 2),
                Text(
                  formatDuration(option.time),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (!isSelected && timeDiff != 0)
                  _buildDiffChip(timeDiff.toDouble(), isPrice: false),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(LegOptionGroup group, bool isExpanded, bool isCurrentGroup) {
    Leg? currentInGroup;
    try {
      currentInGroup = group.options.firstWhere((o) => o.id == widget.currentLeg.id);
    } catch (_) {
      currentInGroup = null;
    }
    final representative = currentInGroup ?? group.cheapest;

    return GestureDetector(
      onTap: () {
        setState(() {
          _expandedGroupTitle = isExpanded ? null : group.title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCurrentGroup ? const Color(0xFFEFF6FF) : Colors.white,
          border: Border.all(
            color: isCurrentGroup ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0),
            width: isCurrentGroup ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(group.icon, size: 22, color: Colors.black87),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (group.subtitle != null)
                        Text(group.subtitle!, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'from £${group.cheapest.cost.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      formatDuration(representative.time),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey[400],
                  size: 20,
                ),
              ],
            ),
            // Expanded access mode chips
            if (isExpanded) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'Get there by:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: group.options.map((option) {
                  final isSelected = option.id == widget.currentLeg.id;
                  return GestureDetector(
                    onTap: () => widget.onSelect(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF4F46E5) : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getAccessModeIcon(option),
                            size: 16,
                            color: isSelected ? Colors.white : Colors.black87,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _getAccessModeLabel(option),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '£${option.cost.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiffChip(double diff, {required bool isPrice}) {
    final isPositive = diff > 0;
    final color = isPositive ? Colors.red : Colors.green;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;
    final text = isPrice
        ? (isPositive ? '+£${diff.abs().toStringAsFixed(2)}' : '-£${diff.abs().toStringAsFixed(2)}')
        : (isPositive ? '+${formatDuration(diff.abs().toInt())}' : '-${formatDuration(diff.abs().toInt())}');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color),
        Text(text, style: TextStyle(fontSize: 11, color: color)),
      ],
    );
  }
}
