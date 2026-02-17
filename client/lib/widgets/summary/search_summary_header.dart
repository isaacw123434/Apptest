import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../search_form.dart';

class SearchSummaryHeader extends StatefulWidget {
  final TextEditingController fromController;
  final TextEditingController toController;
  final TextEditingController timeController;
  final String timeType;
  final ValueChanged<String?> onTimeTypeChanged;
  final Map<String, bool> selectedModes;
  final Function(String, bool) onModeChanged;
  final VoidCallback onSearch;
  final String displayFrom;
  final String displayTo;
  final String displayTimeType;
  final String displayTime;

  const SearchSummaryHeader({
    super.key,
    required this.fromController,
    required this.toController,
    required this.timeController,
    required this.timeType,
    required this.onTimeTypeChanged,
    required this.selectedModes,
    required this.onModeChanged,
    required this.onSearch,
    required this.displayFrom,
    required this.displayTo,
    required this.displayTimeType,
    required this.displayTime,
  });

  @override
  State<SearchSummaryHeader> createState() => _SearchSummaryHeaderState();
}

class _SearchSummaryHeaderState extends State<SearchSummaryHeader> {
  bool _isSearchExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSearchExpanded = !_isSearchExpanded;
        });
      },
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC), // Slate 50
            border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
            borderRadius: BorderRadius.circular(8),
          ),
          child: _isSearchExpanded
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SearchForm(
                      fromController: widget.fromController,
                      toController: widget.toController,
                      timeController: widget.timeController,
                      timeType: widget.timeType,
                      onTimeTypeChanged: widget.onTimeTypeChanged,
                      selectedModes: widget.selectedModes,
                      onModeChanged: widget.onModeChanged,
                    ),
                    const SizedBox(height: 16),
                    // Search Button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isSearchExpanded = false;
                        });
                        widget.onSearch();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F46E5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Search'),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            '${widget.displayTimeType} by ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Flexible(
                            child: Text(
                              widget.displayFrom.split(',')[0],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(LucideIcons.arrowRight, size: 12, color: Colors.grey),
                          ),
                          Flexible(
                            child: Text(
                              widget.displayTo.split(',')[0],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${widget.displayTime}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.pencil, size: 16, color: Colors.grey),
                  ],
                ),
        ),
      ),
    );
  }
}
