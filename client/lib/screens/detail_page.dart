import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/emission_utils.dart';

class DetailPage extends StatefulWidget {
  final JourneyResult? journeyResult;

  const DetailPage({super.key, this.journeyResult});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final Distance _distance = const Distance();
  final ApiService _apiService = ApiService();
  InitData? _initData;
  MapController? _mapController;
  List<Polyline> _polylines = [];
  JourneyResult? _currentResult;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.journeyResult != null) {
      _currentResult = widget.journeyResult;
      _updatePolylines();
    }
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchInitData();
      if (mounted) {
        setState(() {
          _initData = data;
        });
        // Explicitly call this AFTER _initData is set to refresh the map
        _updatePolylines();
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _updatePolylines() {
    if (_currentResult == null) return;

    final result = _currentResult!;
    List<Polyline> lines = [];

    // Helper to add segments
    void addSegments(Leg leg) {
      for (var seg in leg.segments) {
        if (seg.path != null && seg.path!.isNotEmpty) {
          // Filter out invalid coordinates
          final validPoints = seg.path!.where((p) => p.latitude.abs() <= 90).toList();
          if (validPoints.isNotEmpty) {
            final points = validPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

            lines.add(Polyline(
              points: points,
              color: _parseColor(seg.lineColor),
              strokeWidth: 6.0,
            ));
          }
        }
      }
    }

    // Leg 1
    addSegments(result.leg1);

    // Main Leg
    if (_initData != null) {
      addSegments(_initData!.segmentOptions.mainLeg);
    }

    // Leg 3
    addSegments(result.leg3);

    // Fallback if no lines generated yet, try mock path
    if (lines.isEmpty && _initData != null && _initData!.mockPath.isNotEmpty) {
       final mockPoints = _initData!.mockPath.map((p) => LatLng(p.latitude, p.longitude)).toList();
       lines.add(Polyline(
         points: mockPoints,
         color: Colors.blue,
         strokeWidth: 4.0,
       ));
    }

    setState(() {
      _polylines = lines;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
       _zoomToFit();
    });
  }

  Color _parseColor(String lineColor) {
    try {
      return Color(int.parse(lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF4F46E5); // Brand Blue as fallback
    }
  }

  void _updateLeg(String legType, Leg newLeg) {
    if (_currentResult == null || _initData == null) return;

    setState(() {
      Leg leg1 = legType == 'firstMile' ? newLeg : _currentResult!.leg1;
      Leg leg3 = legType == 'lastMile' ? newLeg : _currentResult!.leg3;
      Leg mainLeg = _initData!.segmentOptions.mainLeg;

      // Recalculate totals
      double cost = leg1.cost + mainLeg.cost + leg3.cost;
      int buffer = 10;
      int time = leg1.time + buffer + mainLeg.time + leg3.time;
      int risk = leg1.riskScore + mainLeg.riskScore + leg3.riskScore;

      // Calculate Emissions
      // We need direct drive data to calculate savings properly, but for now we can just update the object
      // Assuming directDriveData is constant or we can get it from InitData if we passed it fully.
      // InitData has directDrive.
      double carEmission = _initData!.directDrive.co2 ?? (_initData!.directDrive.distance * 0.27);

      double totalEmission = (leg1.co2 ?? leg1.distance * getEmissionFactor(leg1.iconId)) +
          (mainLeg.co2 ?? mainLeg.distance * getEmissionFactor(mainLeg.iconId)) +
          (leg3.co2 ?? leg3.distance * getEmissionFactor(leg3.iconId));

      double savings = carEmission - totalEmission;
      int savingsPercent = 0;
      if (carEmission > 0) {
         savingsPercent = ((savings / carEmission) * 100).round();
      }

      _currentResult = JourneyResult(
        id: '${leg1.id}-${leg3.id}',
        leg1: leg1,
        leg3: leg3,
        cost: cost,
        time: time,
        buffer: buffer,
        risk: risk,
        emissions: Emissions(
            val: savings,
            percent: savingsPercent,
            text: savings > 0 ? 'Saves $savingsPercent% CO₂ vs driving' : null
        ),
      );

      _updatePolylines();
    });
  }

  void _showEditModal(String legType) {
    if (_initData == null || _currentResult == null) return;

    List<Leg> options = legType == 'firstMile'
        ? _initData!.segmentOptions.firstMile
        : _initData!.segmentOptions.lastMile;

    Leg currentLeg = legType == 'firstMile'
        ? _currentResult!.leg1
        : _currentResult!.leg3;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Choose ${legType == 'firstMile' ? 'First Mile' : 'Last Mile'}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: options.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option.id == currentLeg.id;

                    // Calculate diffs
                    double priceDiff = option.cost - currentLeg.cost;
                    int timeDiff = option.time - currentLeg.time;

                    return GestureDetector(
                      onTap: () {
                        _updateLeg(legType, option);
                        Navigator.pop(context);
                      },
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
                            // Icon
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIconData(option.iconId), size: 24, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    option.detail ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            // Metrics
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Price
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
                                // Time
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
                                          ? '${option.time} min'
                                          : (timeDiff > 0 ? '+${timeDiff.abs()} min' : '-${timeDiff.abs()} min'),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentResult == null) {
      return const Scaffold(body: Center(child: Text('No journey selected')));
    }

    if (_initData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final result = _currentResult!;
    final totalCost = result.cost;
    final totalTime = result.time;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(53.28, -1.37),
              initialZoom: 9.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
            ],
          ),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: FloatingActionButton.small(
              heroTag: 'back_fab',
              onPressed: () => Navigator.pop(context),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              child: const Icon(LucideIcons.chevronLeft),
            ),
          ),

          // Debug Button
          Positioned(
            top: 40,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'debug_fab',
              onPressed: _showDebugInfo,
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              child: const Icon(LucideIcons.bug),
            ),
          ),

          // 2. Sliding Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.25, 0.35, 0.9],
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: CustomScrollView(
                  controller: scrollController,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Handle
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: Container(
                                width: 48,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),

                          // Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '£${totalCost.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A), // Slate 900
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(totalTime / 60).floor()}h ${totalTime % 60}m',
                                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5), // Emerald 50
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.leaf, size: 12, color: Color(0xFF047857)),
                                      const SizedBox(width: 4),
                                      Text(
                                        result.emissions.text != null
                                            ? '${result.emissions.val.toStringAsFixed(2)} kg CO₂'
                                            : 'Low CO₂',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(),
                        ],
                      ),
                    ),

                    // Timeline
                    SliverPadding(
                      padding: const EdgeInsets.all(24),
                      sliver: SliverToBoxAdapter(
                        child: _buildVerticalNodeTimeline(result),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                ),
              );
            },
          ),

          // Save Button
          Positioned(
            left: 24,
            right: 24,
            bottom: 24,
            child: ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(LucideIcons.heart),
              label: const Text('Save Route'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), // Brand
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalNodeTimeline(JourneyResult result) {
    if (_initData == null) return const Center(child: CircularProgressIndicator());

    // Calculate times - Base is Main Leg Departure at 08:03
    final int leedsDepartMinutes = 8 * 60 + 3; // 08:03
    final int leedsArrivalMinutes = leedsDepartMinutes - result.buffer;
    final int startMinutes = leedsArrivalMinutes - result.leg1.time;

    int currentMinutes = startMinutes;

    List<Widget> children = [];

    // Helper to add segments
    void addSegments(Leg leg, {bool isEditable = false, required VoidCallback? onEdit}) {
      final segments = leg.segments;
      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isFirst = i == 0;
        final isLast = i == segments.length - 1;

        Color lineColor = _parseColor(seg.lineColor);

        // Calculate Distance
        double? distance;
        if (seg.path != null && seg.path!.isNotEmpty) {
          double totalMeters = 0;
          for (int j = 0; j < seg.path!.length - 1; j++) {
            totalMeters += _distance.as(LengthUnit.Meter, seg.path![j], seg.path![j + 1]);
          }
          distance = totalMeters / 1609.34; // Convert to miles
        }

        // Determine extra details
        String? extraDetails;
        if (seg.iconId == 'train' && leg.platform != null) {
          extraDetails = 'Platform ${leg.platform}';
        } else if (seg.iconId == 'bus' && leg.nextBusIn != null) {
          extraDetails = 'Bus every ${leg.nextBusIn} mins';
        } else if ((seg.iconId == 'car' || seg.mode == 'taxi') && leg.waitTime != null) {
          extraDetails = 'Est wait: ${leg.waitTime} min';
        } else if (seg.iconId == 'bike' && leg.desc != null) {
          extraDetails = leg.desc;
        }

        children.add(_buildSegmentConnection(
          segment: seg,
          isEditable: isEditable && isFirst, // Only first segment gets edit button
          onEdit: onEdit,
          distance: distance,
          extraDetails: extraDetails,
        ));

        currentMinutes += seg.time;

        if (!isLast) {
          children.add(_buildNode(
              seg.to ?? 'Stop',
              _formatMinutes(currentMinutes),
              prevColor: lineColor,
              nextColor: _parseColor(segments[i + 1].lineColor)));
        }
      }
    }

    // --- Start Node ---
    Color leg1FirstColor = _parseColor(result.leg1.segments.first.lineColor);
    children.add(_buildNode('Start Journey', _formatMinutes(currentMinutes),
        isStart: true, nextColor: leg1FirstColor));

    // --- Leg 1 ---
    addSegments(result.leg1, isEditable: true, onEdit: () => _showEditModal('firstMile'));

    // --- Leeds Node ---
    // Time range: Arrival - Depart
    String leedsTimeStr =
        '${_formatMinutes(currentMinutes)} - ${_formatMinutes(currentMinutes + result.buffer)}';
    Color leg1LastColor = _parseColor(result.leg1.segments.last.lineColor);
    Color mainLegColor = _parseColor(_initData!.segmentOptions.mainLeg.segments.first.lineColor);

    children.add(_buildNode('Leeds Station', leedsTimeStr,
        prevColor: leg1LastColor, nextColor: mainLegColor));
    currentMinutes += result.buffer;

    // --- Main Leg ---
    addSegments(_initData!.segmentOptions.mainLeg, isEditable: false, onEdit: null);

    // --- Loughborough Node ---
    Color mainLegLastColor =
        _parseColor(_initData!.segmentOptions.mainLeg.segments.last.lineColor);
    Color leg3FirstColor = _parseColor(result.leg3.segments.first.lineColor);

    children.add(_buildNode('Loughborough Station', _formatMinutes(currentMinutes),
        prevColor: mainLegLastColor, nextColor: leg3FirstColor));

    // --- Leg 3 ---
    addSegments(result.leg3, isEditable: true, onEdit: () => _showEditModal('lastMile'));

    // --- End Node ---
    Color leg3LastColor = _parseColor(result.leg3.segments.last.lineColor);
    children.add(_buildNode(
      'Arrive East Leake',
      _formatMinutes(currentMinutes),
      isEnd: true,
      prevColor: leg3LastColor
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  String _formatMinutes(int totalMinutes) {
    int hour = (totalMinutes ~/ 60) % 24;
    int minute = totalMinutes % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  Widget _buildNode(String title, String time, {
    bool isStart = false,
    bool isEnd = false,
    Color? prevColor,
    Color? nextColor,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 16,
            child: Column(
              children: [
                // Line above (if not start)
                Expanded(
                  child: isStart
                      ? const SizedBox()
                      : Container(
                          width: 4,
                          color: prevColor ?? Colors.grey[300],
                        ),
                ),

                // Dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 3),
                  ),
                ),

                // Line below (if not end)
                Expanded(
                  child: isEnd
                      ? const SizedBox()
                      : Container(
                          width: 4,
                          color: nextColor ?? Colors.grey[300],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentConnection({
    required Segment segment,
    bool isEditable = false,
    VoidCallback? onEdit,
    double? distance,
    String? extraDetails,
  }) {
    // Prefer segment.distance if available
    final displayDistance = segment.distance ?? distance;
    final emission = segment.co2 ?? (displayDistance != null ? calculateEmission(displayDistance, segment.iconId) : 0.0);
    Color lineColor = _parseColor(segment.lineColor);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 4,
                    color: lineColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Content
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Icon(_getIconData(segment.iconId), color: lineColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(segment.label,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${segment.time} min${displayDistance != null ? ' • ${displayDistance.toStringAsFixed(1)} miles' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (displayDistance != null || emission > 0)
                          Row(
                            children: [
                              const Icon(LucideIcons.leaf,
                                  size: 10, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${emission.toStringAsFixed(2)} kg CO₂',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        if (extraDetails != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            extraDetails,
                            style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey,
                                fontStyle: FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isEditable)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF4F46E5),
                        textStyle:
                            const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
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

  void _showDebugInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Debug Info'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Polylines: ${_polylines.length}'),
                const Divider(),
                ..._polylines.map((p) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Points: ${p.points.length}'),
                    if (p.points.isNotEmpty)
                      Text('First: ${p.points.first.latitude.toStringAsFixed(4)}, ${p.points.first.longitude.toStringAsFixed(4)}'),
                    const SizedBox(height: 8),
                  ],
                )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _zoomToFit();
              },
              child: const Text('Zoom to Fit'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _zoomToFit() {
    if (_mapController == null || _polylines.isEmpty) return;

    List<LatLng> allPoints = [];
    for (var polyline in _polylines) {
      allPoints.addAll(polyline.points);
    }

    if (allPoints.isEmpty) return;

    double minLat = allPoints.first.latitude;
    double maxLat = allPoints.first.latitude;
    double minLng = allPoints.first.longitude;
    double maxLng = allPoints.first.longitude;

    for (var point in allPoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    _mapController!.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
  }
}
