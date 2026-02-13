import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import 'detail_page.dart';
import 'direct_drive_page.dart';
import 'horizontal_jigsaw_schematic.dart';

class SummaryPage extends StatefulWidget {
  final String from;
  final String to;
  final String timeType;
  final String time;
  final Map<String, bool> selectedModes;

  const SummaryPage({
    super.key,
    required this.from,
    required this.to,
    required this.timeType,
    required this.time,
    required this.selectedModes,
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
  bool _isModeDropdownOpen = false;

  final List<Map<String, dynamic>> _modeOptions = [
    {'id': 'train', 'icon': LucideIcons.train, 'label': 'Train'},
    {'id': 'bus', 'icon': LucideIcons.bus, 'label': 'Bus'},
    {'id': 'car', 'icon': LucideIcons.car, 'label': 'Car'},
    {'id': 'taxi', 'icon': LucideIcons.car, 'label': 'Taxi'},
    {'id': 'bike', 'icon': LucideIcons.bike, 'label': 'Bike'},
  ];

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
      final initData = await _apiService.fetchInitData();
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5), // Brand
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
            child: const Text(
              'EndMile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3730A3), // Brand Dark
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
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
                    // Start
                    Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _fromController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(height: 24),
                    // End
                    Text(
                      'End',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _toController,
                      readOnly: true,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const Divider(height: 24),
                    // Time
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: _timeType,
                          underline: Container(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                          icon: const Icon(LucideIcons.chevronDown, size: 14, color: Colors.grey),
                          onChanged: null,
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
                            controller: _timeController,
                            readOnly: true,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
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
                    const SizedBox(height: 16),
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
                                color: Color(0xFF64748B), // Slate 500
                              ),
                            ),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 16,
                              color: const Color(0xFF64748B), // Slate 500
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
                          final isSelected = _selectedModes[mode['id']]!;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: index == _modeOptions.length - 1 ? 0 : 8.0),
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedModes[mode['id']] = !isSelected;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEFF6FF) : Colors.white, // Blue 50
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFFE2E8F0), // Accent or Slate 200
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        mode['icon'],
                                        size: 20,
                                        color: isSelected ? const Color(0xFF4F46E5) : const Color(0xFF94A3B8),
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
            builder: (context) => const DirectDrivePage(),
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
                  '${(_directDrive!.time / 60).floor()}h ${_directDrive!.time % 60}m',
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

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailPage(journeyResult: result),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '£${result.cost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A), // Slate 900
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${(result.time / 60).floor()}hr ${result.time % 60}m',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A), // Slate 900
                                ),
                              ),
                              Builder(
                                builder: (context) {
                                  final times = _calculateJourneyTimes(result);
                                  return Text(
                                    '${_formatTime(times['start']!)} - ${_formatTime(times['end']!)}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  );
                                }
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Schematic
                      SizedBox(
                        height: 45,
                        child: _buildSchematic(result),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (isLeastRisky)
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => Dialog(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(24.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEFF6FF), // Blue 50
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Icon(LucideIcons.shield, color: Color(0xFF4F46E5)),
                                              ),
                                              const SizedBox(width: 12),
                                              const Text(
                                                'Risk Assessment',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'This journey has the lowest risk score.',
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 12),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC), // Slate 50
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFE2E8F0)),
                                            ),
                                            child: Column(
                                              children: [
                                                _buildRiskRow('First Mile', result.leg1),
                                                const SizedBox(height: 12),
                                                _buildRiskRow('Main Leg', _mainLeg, scoreOverride: result.risk - result.leg1.riskScore - result.leg3.riskScore),
                                                const SizedBox(height: 12),
                                                _buildRiskRow('Last Mile', result.leg3),
                                                const Divider(height: 16),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    const Text('Total Score', style: TextStyle(fontWeight: FontWeight.bold)),
                                                    Text(result.risk.toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Calculated based on historical delay data, number of transfers, and connection buffer times.',
                                            style: TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 24),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () => Navigator.pop(context),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF4F46E5),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Close'),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF), // Blue 50
                                  border: Border.all(color: const Color(0xFFDBEAFE)), // Blue 100
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(LucideIcons.shield, size: 12, color: Color(0xFF1D4ED8)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Least Risky',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1D4ED8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (result.emissions.text != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5), // Emerald 50
                                border: Border.all(color: const Color(0xFFD1FAE5)), // Emerald 100
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(LucideIcons.leaf, size: 12, color: Color(0xFF047857)),
                                  const SizedBox(width: 4),
                                  Text(
                                    result.emissions.text!,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isTopChoice)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    color: const Color(0xFFECFDF5), // Emerald 50
                    child: const Text(
                      'TOP CHOICE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF047857), // Emerald 700
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSchematic(JourneyResult result) {
    // A simplified visual representation of the journey segments
    List<Segment> allSegments = [];

    // Leg 1
    allSegments.addAll(result.leg1.segments);

    // Main Leg
    if (_mainLeg != null) {
      allSegments.addAll(_mainLeg!.segments);
    } else {
      // Fallback if mainLeg not loaded yet (shouldn't happen often if we sync loading, but for safety)
      allSegments.add(Segment(
          mode: 'train',
          label: 'CrossCountry',
          lineColor: '#713e8d',
          iconId: 'train',
          time: 102));
    }

    // Leg 3
    allSegments.addAll(result.leg3.segments);

    final processedSegments = _processSegments(allSegments);

    double totalTime = result.time.toDouble();
    // Safety check for totalTime
    if (totalTime == 0) totalTime = 1;

    return HorizontalJigsawSchematic(
      segments: processedSegments,
      totalTime: totalTime,
    );
  }

  List<Segment> _processSegments(List<Segment> rawSegments) {
    List<Segment> processed = [];

    // 1. Filter out short walks (<= 2 mins)
    for (var seg in rawSegments) {
      bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.iconId == 'footprints';
      if (isWalk && seg.time <= 2) {
        continue;
      }
      processed.add(seg);
    }

    // 2. Merge Walk - Transfer - Walk
    List<Segment> mergedWalks = [];
    int i = 0;
    while (i < processed.length) {
      final seg = processed[i];
      bool isWalk = seg.mode.toLowerCase() == 'walk' || seg.iconId == 'footprints';

      if (isWalk && i + 2 < processed.length) {
        final next = processed[i + 1];
        final nextNext = processed[i + 2];
        bool isNextWait = next.mode.toLowerCase() == 'wait' || next.label.toLowerCase() == 'transfer';
        bool isNextNextWalk = nextNext.mode.toLowerCase() == 'walk' || nextNext.iconId == 'footprints';

        if (isNextWait && isNextNextWalk) {
          // Merge
          mergedWalks.add(Segment(
            mode: 'walk',
            label: 'Walk',
            lineColor: seg.lineColor,
            iconId: seg.iconId,
            time: seg.time + next.time + nextNext.time,
            to: nextNext.to,
            detail: seg.detail,
          ));
          i += 3;
          continue;
        }
      }
      mergedWalks.add(seg);
      i++;
    }
    processed = mergedWalks;

    // 3. Merge Consecutive Trains (CrossCountry + EMR only)
    List<Segment> mergedTrains = [];
    i = 0;
    while (i < processed.length) {
      final seg = processed[i];
      bool isTrain = seg.iconId == 'train';

      if (isTrain && i + 1 < processed.length) {
         final next = processed[i + 1];
         bool isNextTrain = next.iconId == 'train';

         if (isNextTrain) {
           String label1 = seg.label.replaceAll('E M R', 'EMR');
           String label2 = next.label.replaceAll('E M R', 'EMR');

           bool isMergeable = (label1.contains('CrossCountry') && label2.contains('EMR')) ||
                              (label1.contains('EMR') && label2.contains('CrossCountry'));

           if (isMergeable) {
             // Merge
             mergedTrains.add(Segment(
               mode: 'train',
               label: '$label1 + $label2',
               lineColor: seg.lineColor,
               iconId: 'train',
               time: seg.time + next.time,
               to: next.to,
               detail: seg.detail,
             ));
             i += 2;
             continue;
           }
         }
      }
      mergedTrains.add(seg);
      i++;
    }
    processed = mergedTrains;

    // 4. Final pass: Fix EMR labels (if not merged)
    List<Segment> finalPass = [];
    for (var seg in processed) {
      String label = seg.label.replaceAll('E M R', 'EMR');

      if (label != seg.label) {
        finalPass.add(Segment(
          mode: seg.mode,
          label: label,
          lineColor: seg.lineColor,
          iconId: seg.iconId,
          time: seg.time,
          to: seg.to,
          detail: seg.detail,
          path: seg.path,
          co2: seg.co2,
          distance: seg.distance,
        ));
      } else {
        finalPass.add(seg);
      }
    }

    return finalPass;
  }

  Map<String, TimeOfDay> _calculateJourneyTimes(JourneyResult result) {
    // Main Leg Departure = 8:03 AM (483 minutes)
    final int mainLegDepartMinutes = 8 * 60 + 3;
    final int startMinutes = mainLegDepartMinutes - result.buffer - result.leg1.time;
    // End Time = Start + Duration
    final int endMinutes = startMinutes + result.time;

    return {
      'start': _minutesToTimeOfDay(startMinutes),
      'end': _minutesToTimeOfDay(endMinutes),
    };
  }

  TimeOfDay _minutesToTimeOfDay(int totalMinutes) {
    // Handle wraparound
    totalMinutes = totalMinutes % (24 * 60);
    if (totalMinutes < 0) totalMinutes += 24 * 60;

    return TimeOfDay(
      hour: totalMinutes ~/ 60,
      minute: totalMinutes % 60,
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildRiskRow(String title, Leg? leg, {int? scoreOverride}) {
    final score = scoreOverride ?? leg?.riskScore ?? 0;
    final reason = leg?.riskReason;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFF64748B))),
            Text(score.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        if (reason != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              reason,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B), // Slate 500
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}
