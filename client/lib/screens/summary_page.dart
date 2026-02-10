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
  bool _isLoading = true;
  String _activeTab = 'smart'; // smart, fastest, cheapest
  String? _errorMessage;
  final Map<String, List<JourneyResult>> _resultsCache = {};

  @override
  void initState() {
    super.initState();
    _fetchInitData();
    _fetchTabResults();
  }

  Future<void> _fetchInitData() async {
    try {
      final initData = await _apiService.fetchInitData();
      if (mounted) {
        setState(() {
          _directDrive = initData.directDrive;
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
        selectedModes: widget.selectedModes,
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
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC), // Slate 50
          border: Border.all(color: const Color(0xFFE2E8F0)), // Slate 200
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    '${widget.timeType} by ',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  Flexible(
                    child: Text(
                      widget.from.split(',')[0],
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
                      widget.to.split(',')[0],
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${widget.time}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.pencil, size: 16, color: Colors.grey),
          ],
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
              borderRadius: BorderRadius.circular(16),
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
                              if (result.buffer > 0)
                                Text(
                                  'incl. ${result.buffer}m wait',
                                  style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
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
                              Text(
                                '07:10 - 09:26', // Mock logic for time range
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Schematic
                      SizedBox(
                        height: 40,
                        child: _buildSchematic(result),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (isLeastRisky)
                            Container(
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

    // Main Leg (Hardcoded in original service as constant, but absent in JourneyResult legs)
    // We can manually add it
    allSegments.add(Segment(
      mode: 'train',
      label: 'CrossCountry',
      lineColor: '#713e8d',
      iconId: 'train',
      time: 102
    ));

    // Leg 3
    allSegments.addAll(result.leg3.segments);

    double totalTime = result.time.toDouble();
    // Safety check for totalTime
    if (totalTime == 0) totalTime = 1;

    return HorizontalJigsawSchematic(
      segments: allSegments,
      totalTime: totalTime,
    );
  }

  IconData _getIconData(String iconId) {
    switch (iconId) {
      case 'train': return LucideIcons.train;
      case 'bus': return LucideIcons.bus;
      case 'car': return LucideIcons.car;
      case 'bike': return LucideIcons.bike;
      case 'footprints': return LucideIcons.footprints;
      default: return LucideIcons.circle;
    }
  }
}
