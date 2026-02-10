import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Build initial polylines from available journey result data
    if (widget.journeyResult != null) {
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
          _updatePolylines();
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  void _updatePolylines() {
    if (widget.journeyResult == null) return;

    final result = widget.journeyResult!;
    List<Polyline> lines = [];

    // Helper to add segments
    void addSegments(Leg leg) {
      for (var seg in leg.segments) {
        if (seg.path != null && seg.path!.isNotEmpty) {
          lines.add(Polyline(
            points: seg.path!,
            color: _parseColor(seg.lineColor),
            strokeWidth: 4.0,
          ));
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

  @override
  Widget build(BuildContext context) {
    if (widget.journeyResult == null) {
      return const Scaffold(body: Center(child: Text('No journey selected')));
    }

    final result = widget.journeyResult!;
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
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 8),
                        width: 48,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
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
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(24),
                        children: [
                          _buildTimelineStep(
                            time: '07:10',
                            icon: null,
                            lineColor: result.leg1.lineColor, // Start line color
                            content: const Text('Start Journey', style: TextStyle(fontWeight: FontWeight.bold)),
                            isStart: true,
                          ),
                          ..._buildLegSegments(result.leg1),
                          // Buffer
                          _buildBufferStep(result.buffer),
                          // Main Leg
                          if (_initData != null) ..._buildLegSegments(_initData!.segmentOptions.mainLeg),
                          // Leg 3
                          ..._buildLegSegments(result.leg3),

                          _buildTimelineStep(
                            time: '09:26', // Mock arrival
                            icon: null,
                            lineColor: result.leg3.lineColor,
                            content: const Text('Arrive East Leake', style: TextStyle(fontWeight: FontWeight.bold)),
                            isEnd: true,
                          ),

                          const SizedBox(height: 80), // Space for button
                        ],
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

  List<Widget> _buildLegSegments(Leg leg) {
    List<Widget> widgets = [];
    for (var segment in leg.segments) {
      widgets.add(_buildTimelineStep(
        time: '${segment.time} min',
        icon: _getIconData(segment.iconId),
        lineColor: segment.lineColor,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(segment.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(segment.detail ?? segment.to ?? '', style: const TextStyle(color: Colors.grey)),
            if (leg.waitTime != null && segment.mode == 'taxi')
               Text('Est wait: ${leg.waitTime} min', style: const TextStyle(color: Colors.amber, fontSize: 12)),
            if (leg.nextBusIn != null && segment.mode == 'bus')
               Text('Next bus in ${leg.nextBusIn} min', style: const TextStyle(color: Colors.green, fontSize: 12)),
          ],
        ),
      ));
    }
    return widgets;
  }

  Widget _buildBufferStep(int buffer) {
    if (buffer <= 0) return const SizedBox.shrink();
    return _buildTimelineStep(
      time: '$buffer min',
      icon: LucideIcons.clock,
      lineColor: '#CBD5E1', // Slate 300
      content: const Text('Transfer / Wait', style: TextStyle(color: Colors.grey)),
      isBuffer: true,
    );
  }

  Widget _buildTimelineStep({
    required String time,
    IconData? icon,
    required String lineColor,
    required Widget content,
    bool isStart = false,
    bool isEnd = false,
    bool isBuffer = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              time,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isBuffer ? Colors.grey : Colors.black,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            children: [
              if (!isStart) Expanded(child: Container(width: 2, color: _parseColor(lineColor))),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isStart || isEnd ? (isEnd ? Colors.black : Colors.white) : Colors.white,
                  border: Border.all(color: isEnd ? Colors.black : _parseColor(lineColor), width: 2),
                  shape: BoxShape.circle,
                ),
              ),
              if (!isEnd) Expanded(child: Container(width: 2, color: _parseColor(lineColor))),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: content,
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
