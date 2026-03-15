import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../providers/saved_routes_provider.dart';
import '../widgets/header.dart';
import '../widgets/journey_result_card.dart';
import '../widgets/timeline_summary_view.dart';
import '../widgets/scale_on_press.dart';
import '../widgets/summary/driving_baseline_card.dart';
import '../widgets/summary/journey_tabs.dart';
import '../widgets/summary/search_summary_header.dart';
import 'saved_routes_page.dart';

class SummaryPage extends StatefulWidget {
  final String from;
  final String to;
  final String timeType;
  final String time;
  final Map<String, bool> selectedModes;
  final String? routeId;
  final ApiService? apiService;

  const SummaryPage({
    super.key,
    required this.from,
    required this.to,
    required this.timeType,
    required this.time,
    required this.selectedModes,
    this.routeId,
    this.apiService,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  late final ApiService _apiService;

  List<JourneyResult> _results = [];
  DirectDrive? _directDrive;
  Leg? _mainLeg;
  bool _isLoading = true;
  final Set<String> _expandedTabs = {};
  String _activeTab = 'smart'; // smart, fastest, cheapest
  String? _errorMessage;
  final Map<String, List<JourneyResult>> _resultsCache = {};

  late TextEditingController _fromController;
  late TextEditingController _toController;
  late TextEditingController _timeController;
  late String _timeType;
  late Map<String, bool> _selectedModes;

  // Display values
  late String _displayFrom;
  late String _displayTo;
  late String _displayTimeType;
  late String _displayTime;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _displayFrom = widget.from;
    _displayTo = widget.to;
    _displayTimeType = widget.timeType;
    _displayTime = widget.time;

    _fromController = TextEditingController(text: widget.from);
    _toController = TextEditingController(text: widget.to);
    _timeController = TextEditingController(text: widget.time);
    _timeType = widget.timeType;
    _selectedModes = Map.from(widget.selectedModes);

    _fetchInitData();
    _fetchTabResults();
  }

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _fetchInitData() async {
    try {
      final initData = await _apiService.fetchInitData(routeId: widget.routeId);
      if (mounted) {
        setState(() {
          _directDrive = initData.directDrive;
          _mainLeg = initData.segmentOptions.mainLeg;
        });
      }
    } catch (e) {
      debugPrint('Error fetching init data: $e');
    }
  }

  Future<void> _fetchTabResults() async {
    if (_resultsCache.containsKey(_activeTab)) {
      setState(() {
        _results = _resultsCache[_activeTab]!;
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await _apiService.searchJourneys(
        tab: _activeTab,
        selectedModes: _selectedModes,
        routeId: widget.routeId,
      );

      _resultsCache[_activeTab] = results;

      if (mounted) {
        setState(() {
          _results = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onTabChanged(String tab) {
    if (_activeTab != tab) {
      setState(() {
        _activeTab = tab;
      });
      _fetchTabResults();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: Stack(
          children: [
            Column(
          children: [
            const Header(),
            SearchSummaryHeader(
              fromController: _fromController,
              toController: _toController,
              timeController: _timeController,
              timeType: _timeType,
              onTimeTypeChanged: (value) {
                if (value != null) {
                  setState(() {
                    _timeType = value;
                  });
                }
              },
              selectedModes: _selectedModes,
              onModeChanged: (modeId, isSelected) {
                setState(() {
                  final newModes = Map<String, bool>.from(_selectedModes);
                  newModes[modeId] = isSelected;
                  _selectedModes = newModes;
                });
              },
              onSearch: () {
                setState(() {
                  _displayFrom = _fromController.text;
                  _displayTo = _toController.text;
                  _displayTime = _timeController.text;
                  _displayTimeType = _timeType;
                  _resultsCache.clear();
                });
                _fetchInitData();
                _fetchTabResults();
              },
              displayFrom: _displayFrom,
              displayTo: _displayTo,
              displayTimeType: _displayTimeType,
              displayTime: _displayTime,
            ),
            if (_directDrive != null)
              DrivingBaselineCard(
                directDrive: _directDrive!,
                routeId: widget.routeId,
              ),
            JourneyTabs(
              activeTab: _activeTab,
              onTabChanged: _onTabChanged,
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                      ? Center(child: Text('Error: $_errorMessage'))
                      : _buildResultsList(),
            ),
          ],
            ),
            // Floating heart FAB
            Positioned(
              right: 16,
              bottom: 16,
              child: Consumer<SavedRoutesProvider>(
                builder: (context, provider, _) {
                  final count = provider.countForPair(_displayFrom, _displayTo);
                  if (count == 0) return const SizedBox.shrink();
                  return _HeartFab(
                    count: count,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SavedRoutesPage(
                            from: _displayFrom,
                            to: _displayTo,
                            routeId: widget.routeId,
                            selectedModes: _selectedModes,
                            mainLeg: _mainLeg,
                          ),
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

  Widget _buildResultsList() {
    // Find min risk for "Least Risky" badge
    int minRisk = 999;
    if (_results.isNotEmpty) {
      minRisk = _results.map((r) => r.risk).reduce((a, b) => a < b ? a : b);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate effective width available for the timeline view
        // ListView padding: 16 * 2 = 32
        // Card content padding: 16 * 2 = 32
        // Border: 1 * 2 = 2
        // Total padding deduction: 66
        // We subtract a bit more (70) to be safe and avoid edge case discrepancies
        final double availableWidth = constraints.maxWidth - 70;
        final textScaler = MediaQuery.of(context).textScaler;

        bool forceLogos = false;

        // Check if any card requires logos based on space
        for (var result in _results) {
          final segments = JourneyResultCard.buildSegments(result, _mainLeg);
          if (TimelineSummaryView.checkIfLogosNeeded(
              segments, availableWidth, textScaler)) {
            forceLogos = true;
            break;
          }
        }

        final int initialCount = 3;
        final bool hasMore = _results.length > initialCount;
        final bool showAll = _expandedTabs.contains(_activeTab);
        final int displayedCount =
            (showAll || !hasMore) ? _results.length : initialCount;
        final int itemCount =
            displayedCount + (hasMore && !showAll ? 1 : 0);

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (hasMore && !showAll && index == displayedCount) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _expandedTabs.add(_activeTab);
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'View all routes',
                    style: const TextStyle(
                      color: Color(0xFF475569), // Slate 600
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            }

            final result = _results[index];
            final isTopChoice = index == 0;
            final isLeastRisky = result.risk == minRisk;

            return JourneyResultCard(
              result: result,
              isTopChoice: isTopChoice,
              isLeastRisky: isLeastRisky,
              routeId: widget.routeId,
              mainLeg: _mainLeg,
              selectedModes: _selectedModes,
              forceLogos: forceLogos,
              from: _displayFrom,
              to: _displayTo,
            );
          },
        );
      },
    );
  }
}

class _HeartFab extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const _HeartFab({required this.count, required this.onTap});

  @override
  State<_HeartFab> createState() => _HeartFabState();
}

class _HeartFabState extends State<_HeartFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_HeartFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: ScaleOnPress(
        onTap: widget.onTap,
        child: SizedBox(
          width: 58,
          height: 58,
          child: Stack(
            children: [
              Positioned(
                bottom: 0,
                left: 0,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.favorite, color: Colors.white, size: 24),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.red, width: 1.5),
                  ),
                  child: Text(
                    '${widget.count}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
