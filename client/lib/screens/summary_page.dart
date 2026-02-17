import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/time_utils.dart';
import '../widgets/header.dart';
import '../widgets/search_form.dart';
import '../widgets/journey_result_card.dart';
import 'direct_drive_page.dart';

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
  bool _isSearchExpanded = false;

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
            _buildHeader(),
            _buildSearchSummary(),
            if (_directDrive != null) _buildDrivingBaselineCard(),
            _buildTabs(),
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

  Widget _buildHeader() {
    return const Header();
  }

  Widget _buildSearchSummary() {
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
                          _selectedModes[modeId] = isSelected;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Search Button
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _displayFrom = _fromController.text;
                          _displayTo = _toController.text;
                          _displayTime = _timeController.text;
                          _displayTimeType = _timeType;
                          _isSearchExpanded = false;
                          _resultsCache.clear();
                        });
                        _fetchInitData();
                        _fetchTabResults();
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
                            '$_displayTimeType by ',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Flexible(
                            child: Text(
                              _displayFrom.split(',')[0],
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
                              _displayTo.split(',')[0],
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• $_displayTime',
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

  Widget _buildDrivingBaselineCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DirectDrivePage(
              routeId: widget.routeId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9), // Slate 100
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE2E8F0), // Slate 200
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.car, size: 20, color: Color(0xFF475569)), // Slate 600
                ),
                const SizedBox(width: 12),
                const Text(
                  'Driving',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF334155), // Slate 700
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  '£${_directDrive!.cost.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDC2626), // Red 600
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatDuration(_directDrive!.time),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    color: Color(0xFF64748B), // Slate 500
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      color: Colors.white,
      child: Row(
        children: [
          _buildTab('fastest', 'Fastest', LucideIcons.zap),
          _buildTab('smart', 'Best Value', LucideIcons.shieldCheck),
          _buildTab('cheapest', 'Cheapest', LucideIcons.leaf),
        ],
      ),
    );
  }

  Widget _buildTab(String id, String label, IconData icon) {
    final isActive = _activeTab == id;
    return Expanded(
      child: InkWell(
        onTap: () => _onTabChanged(id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? const Color(0xFF4F46E5) : Colors.transparent,
                width: 2,
              ),
            ),
            color: isActive ? const Color(0xFFE0E7FF).withAlpha(77) : null, // 0.3 * 255 = 76.5
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isActive ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
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
        );
      },
    );
  }
}
