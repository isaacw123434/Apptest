import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../widgets/header.dart';
import '../widgets/journey_result_card.dart';
import '../widgets/summary/driving_baseline_card.dart';
import '../widgets/summary/journey_tabs.dart';
import '../widgets/summary/search_summary_header.dart';
import '../widgets/timeline_summary_view.dart';
import '../utils/journey_utils.dart';

class SummaryPage extends StatefulWidget {
  final String from;
  final String to;
  final String timeType;
  final String time;
  final Map<String, bool> selectedModes;
  final String? routeId;

  const SummaryPage({
    super.key,
    required this.from,
    required this.to,
    required this.timeType,
    required this.time,
    required this.selectedModes,
    this.routeId,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final ApiService _apiService = ApiService();

  List<JourneyResult> _results = [];
  DirectDrive? _directDrive;
  Leg? _mainLeg;
  bool _isLoading = true;
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
        child: Column(
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
        // Calculate max required compression level across all results for this tab
        int maxRequiredLevel = 0;
        // Width available for the timeline view:
        // Screen width - List Padding (16*2) - Card Border (1*2) - Card Padding (16*2) = -66
        final double availableWidth = constraints.maxWidth - 66;
        final TextScaler textScaler = MediaQuery.of(context).textScaler;

        for (var result in _results) {
           final segments = collectSchematicSegments(result, _mainLeg);
           final level = TimelineSummaryView.calculateRequiredLevel(segments, availableWidth, textScaler);
           if (level > maxRequiredLevel) {
             maxRequiredLevel = level;
           }
        }

        // If maxRequiredLevel >= 2 (which corresponds to simplifyTrain=true),
        // enforce at least level 2 for all cards to ensure consistent branding.
        int enforcedLevel = 0;
        if (maxRequiredLevel >= 2) {
           enforcedLevel = 2;
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _results.length,
          itemBuilder: (context, index) {
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
              minCompressionLevel: enforcedLevel,
            );
          },
        );
      }
    );
  }
}
