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
  final ApiService _apiService = ApiService();
  InitData? _initData;
  List<Polyline> _polylines = [];
  JourneyResult? _currentResult;

  @override
  void initState() {
    super.initState();
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
          // If we didn't have a result passed in (unlikely), or to ensure mainLeg is correct
          _updatePolylines();
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _updatePolylines() {
    debugPrint('Updating polylines for result: ${_currentResult?.id}');
    if (_currentResult == null) return;

    final result = _currentResult!;
    List<Polyline> lines = [];

    // Helper to add segments
    void addSegments(Leg leg) {
      debugPrint('Processing leg ${leg.id} with ${leg.segments.length} segments');
      for (var seg in leg.segments) {
        if (seg.path != null && seg.path!.isNotEmpty) {
          debugPrint('Segment ${seg.label} has path with ${seg.path!.length} points');
          // Filter out invalid coordinates to prevent map crashes
          final validPoints = seg.path!.where((p) => p.latitude.abs() <= 90).toList();
          if (validPoints.isNotEmpty) {
            lines.add(Polyline(
              points: validPoints,
              color: _parseColor(seg.lineColor),
              strokeWidth: 4.0,
            ));
          } else {
            debugPrint('Segment ${seg.label} has NO valid points');
          }
        } else {
          debugPrint('Segment ${seg.label} has NO path');
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
       lines.add(Polyline(
         points: _initData!.mockPath,
         color: Colors.blue,
         strokeWidth: 4.0,
       ));
    }

    setState(() {
      _polylines = lines;
    });
  }

  Color _parseColor(String lineColor) {
    try {
      return Color(int.parse(lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return Colors.grey;
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
      double carEmission = (_initData!.directDrive.distance) * 0.27;

      double totalEmission = (leg1.distance * getEmissionFactor(leg1.iconId)) +
          (mainLeg.distance * getEmissionFactor(mainLeg.iconId)) +
          (leg3.distance * getEmissionFactor(leg3.iconId));

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

    final result = _currentResult!;
    final totalCost = result.cost;
    final totalTime = result.time;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Map Background
          if (_polylines.isNotEmpty)
            FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(53.28, -1.37), // Approximate midpoint
                initialZoom: 9.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
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
            )
          else
            const Center(child: CircularProgressIndicator()),

          // Back Button
          Positioned(
            top: 40,
            left: 16,
            child: FloatingActionButton.extended(
              onPressed: () => Navigator.pop(context),
              label: const Text('Back'),
              icon: const Icon(LucideIcons.chevronLeft),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
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
                child: Column(
                  children: [
                    // Handle
                    GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      child: Container(
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

                    // Timeline
                    Expanded(
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        child: _buildVerticalNodeTimeline(result),
                      ),
                    ),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Start Node
        _buildNode('Start Journey', '07:10', isStart: true),

        // Leg 1 (First Mile)
        _buildLegConnection(
          leg: result.leg1,
          isEditable: true,
          onEdit: () => _showEditModal('firstMile'),
        ),

        // Transfer Node (Leeds)
        _buildNode('Leeds Station', '07:35'), // Mock time

        // Main Leg (Train)
        _buildLegConnection(
          leg: _initData!.segmentOptions.mainLeg,
          isEditable: false,
        ),

        // Transfer Node (Loughborough)
        _buildNode('Loughborough Station', '09:15'), // Mock time

        // Leg 3 (Last Mile)
        _buildLegConnection(
          leg: result.leg3,
          isEditable: true,
          onEdit: () => _showEditModal('lastMile'),
        ),

        // End Node
        _buildNode('Arrive East Leake', '09:30', isEnd: true),
      ],
    );
  }

  Widget _buildNode(String title, String time, {bool isStart = false, bool isEnd = false}) {
    return Row(
      children: [
        Column(
          children: [
            // Line above (if not start)
            if (!isStart)
              Container(width: 2, height: 10, color: Colors.grey[300]),

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
            if (!isEnd)
              Container(width: 2, height: 10, color: Colors.grey[300]),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildLegConnection({required Leg leg, bool isEditable = false, VoidCallback? onEdit}) {
    final emission = calculateEmission(leg.distance, leg.iconId);
    Color lineColor = _parseColor(leg.lineColor);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line
          SizedBox(
            width: 16,
            child: Center(
              child: Container(
                width: 4,
                color: lineColor,
              ),
            ),
          ),
          const SizedBox(width: 16),
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
                   BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Icon(_getIconData(leg.iconId), color: lineColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(leg.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${leg.time} min • ${(leg.distance).toStringAsFixed(1)} miles',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.leaf, size: 10, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              '${emission.toStringAsFixed(2)} kg CO₂',
                              style: const TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
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
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
}
