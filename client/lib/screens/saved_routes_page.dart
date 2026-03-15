import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models.dart';
import '../providers/saved_routes_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/header.dart';
import '../widgets/journey_result/journey_result_header.dart';
import '../widgets/timeline_summary_view.dart';
import '../widgets/journey_result_card.dart';
import '../widgets/scale_on_press.dart';
import 'detail_page.dart';

class SavedRoutesPage extends StatefulWidget {
  final String from;
  final String to;
  final String? routeId;
  final Map<String, bool> selectedModes;

  const SavedRoutesPage({
    super.key,
    required this.from,
    required this.to,
    this.routeId,
    required this.selectedModes,
  });

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage> {
  String _sortBy = 'fastest';
  final Set<String> _removing = {};
  final Map<String, Timer> _removeTimers = {};

  @override
  void dispose() {
    for (final timer in _removeTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }

  List<SavedRoute> _sortedRoutes(List<SavedRoute> routes) {
    final sorted = List<SavedRoute>.from(routes);
    switch (_sortBy) {
      case 'fastest':
        sorted.sort((a, b) => a.journey.time.compareTo(b.journey.time));
      case 'cheapest':
        sorted.sort((a, b) => a.journey.cost.compareTo(b.journey.cost));
      case 'carbon':
        sorted.sort(
            (a, b) => a.journey.emissions.val.compareTo(b.journey.emissions.val));
      case 'risk':
        sorted.sort((a, b) => a.journey.risk.compareTo(b.journey.risk));
    }
    return sorted;
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back,
                            color: AppColors.slate700),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Saved Routes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.slate900,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                          DropdownMenuItem(value: 'risk', child: Text('Risk')),
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
                  final routes = _sortedRoutes(provider.savedRoutes);
                  if (routes.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.favorite_border,
                              size: 48, color: AppColors.slate400),
                          const SizedBox(height: 12),
                          Text(
                            'No saved routes yet',
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
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: routes.length,
                    itemBuilder: (context, index) {
                      final saved = routes[index];
                      final isRemoving = _removing.contains(saved.journey.id);
                      return _SavedRouteCard(
                        saved: saved,
                        isRemoving: isRemoving,
                        onHeartTap: () {
                          if (isRemoving) {
                            _undoRemoval(saved.journey.id);
                          } else {
                            _startRemoval(saved.journey.id);
                          }
                        },
                        onCardTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetailPage(
                                journeyResult: saved.journey,
                                routeId: widget.routeId,
                                selectedModes: widget.selectedModes,
                                from: saved.from,
                                to: saved.to,
                              ),
                            ),
                          );
                        },
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

class _SavedRouteCard extends StatelessWidget {
  final SavedRoute saved;
  final bool isRemoving;
  final VoidCallback onHeartTap;
  final VoidCallback onCardTap;

  const _SavedRouteCard({
    required this.saved,
    required this.isRemoving,
    required this.onHeartTap,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final result = saved.journey;
    final segments = JourneyResultCard.buildSegments(result, null);
    final totalTime = result.time == 0 ? 1.0 : result.time.toDouble();

    return AnimatedOpacity(
      opacity: isRemoving ? 0.5 : 1.0,
      duration: const Duration(milliseconds: 300),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: isRemoving ? null : onCardTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.slate200),
              boxShadow: const [
                BoxShadow(
                  color: Colors.white,
                  offset: Offset(0, -1),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black12,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route label
                Text(
                  '${saved.from} → ${saved.to}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate400,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                JourneyResultHeader(result: result),
                const SizedBox(height: 12),
                TimelineSummaryView(
                  segments: segments,
                  totalTime: totalTime,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.eco, size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          '${result.emissions.val.toStringAsFixed(1)} kg CO₂',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.warning_amber,
                            size: 14, color: AppColors.slate400),
                        const SizedBox(width: 4),
                        Text(
                          'Risk ${result.risk}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    ),
                    ScaleOnPress(
                      onTap: onHeartTap,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: isRemoving
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Undo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.brand,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(Icons.favorite_border,
                                      size: 20, color: AppColors.slate400),
                                ],
                              )
                            : const Icon(Icons.favorite,
                                size: 20, color: Colors.red),
                      ),
                    ),
                  ],
                ),
                if (saved.isPermanent)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bookmark,
                            size: 14, color: AppColors.brand),
                        const SizedBox(width: 4),
                        Text(
                          'Saved route',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
