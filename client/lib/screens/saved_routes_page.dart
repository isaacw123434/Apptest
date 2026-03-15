import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/saved_routes_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/journey_result_card.dart';
import '../widgets/scale_on_press.dart';

class SavedRoutesPage extends StatefulWidget {
  final String from;
  final String to;
  final String? routeId;
  final Map<String, bool> selectedModes;
  final Leg? mainLeg;

  const SavedRoutesPage({
    super.key,
    required this.from,
    required this.to,
    this.routeId,
    required this.selectedModes,
    this.mainLeg,
  });

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage> {
  String _sortBy = 'fastest';
  bool _ascending = true;
  final Set<String> _removing = {};
  final Map<String, Timer> _removeTimers = {};

  @override
  void dispose() {
    for (final timer in _removeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  List<SavedRoute> _filteredAndSorted(List<SavedRoute> routes) {
    final routeKey = '${widget.from}→${widget.to}';
    var filtered = routes.where((r) => r.routeKey == routeKey).toList();

    int Function(SavedRoute, SavedRoute) comparator;
    switch (_sortBy) {
      case 'fastest':
        comparator = (a, b) => a.journey.time.compareTo(b.journey.time);
      case 'cheapest':
        comparator = (a, b) => a.journey.cost.compareTo(b.journey.cost);
      case 'carbon':
        comparator = (a, b) =>
            a.journey.emissions.val.compareTo(b.journey.emissions.val);
      case 'risk':
        comparator = (a, b) => a.journey.risk.compareTo(b.journey.risk);
      default:
        comparator = (a, b) => a.journey.time.compareTo(b.journey.time);
    }

    filtered.sort((a, b) => _ascending ? comparator(a, b) : comparator(b, a));
    return filtered;
  }

  void _startRemoval(String journeyId) {
    setState(() {
      _removing.add(journeyId);
    });
    _removeTimers[journeyId] = Timer(const Duration(seconds: 2), () {
      if (mounted && _removing.contains(journeyId)) {
        Provider.of<SavedRoutesProvider>(context, listen: false)
            .removeRoute(journeyId);
        setState(() {
          _removing.remove(journeyId);
          _removeTimers.remove(journeyId);
        });
      }
    });
  }

  void _undoRemoval(String journeyId) {
    _removeTimers[journeyId]?.cancel();
    _removeTimers.remove(journeyId);
    setState(() {
      _removing.remove(journeyId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: SafeArea(
        child: Column(
          children: [
            const Header(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Favourite Routes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate900,
                      ),
                    ),
                  ),
                  // Sort direction toggle
                  GestureDetector(
                    onTap: () => setState(() => _ascending = !_ascending),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.slate200),
                      ),
                      child: Icon(
                        _ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 18,
                        color: AppColors.slate700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Sort dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.slate200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate700,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'fastest', child: Text('Fastest')),
                          DropdownMenuItem(
                              value: 'cheapest', child: Text('Cheapest')),
                          DropdownMenuItem(
                              value: 'carbon', child: Text('Carbon')),
                          DropdownMenuItem(
                              value: 'risk', child: Text('Risk')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<SavedRoutesProvider>(
                builder: (context, provider, _) {
                  final routes = _filteredAndSorted(provider.savedRoutes);
                  if (routes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 48, color: AppColors.slate400),
                          const SizedBox(height: 12),
                          Text(
                            'No favourite routes yet',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.slate500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Heart routes from search results to save them here',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  int minRisk = routes
                      .map((r) => r.journey.risk)
                      .reduce((a, b) => a < b ? a : b);

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final saved = routes[index];
                      final isRemoving =
                          _removing.contains(saved.journey.id);

                      return AnimatedOpacity(
                        opacity: isRemoving ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 300),
                        child: Stack(
                          children: [
                            Column(
                              children: [
                                AbsorbPointer(
                                  absorbing: isRemoving,
                                  child: JourneyResultCard(
                                    result: saved.journey,
                                    isTopChoice: false,
                                    isLeastRisky:
                                        saved.journey.risk == minRisk,
                                    routeId: widget.routeId,
                                    mainLeg: widget.mainLeg,
                                    selectedModes: widget.selectedModes,
                                    from: saved.from,
                                    to: saved.to,
                                    showBookmark: true,
                                    onHeartTap: () {
                                      if (isRemoving) {
                                        _undoRemoval(saved.journey.id);
                                      } else {
                                        _startRemoval(saved.journey.id);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            // Undo overlay when removing
                            if (isRemoving)
                              Positioned.fill(
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white
                                        .withValues(alpha: 0.8),
                                    borderRadius:
                                        BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: ScaleOnPress(
                                      onTap: () => _undoRemoval(
                                          saved.journey.id),
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 16,
                                                vertical: 8),
                                        decoration: BoxDecoration(
                                          color: AppColors.brand,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'Undo',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
