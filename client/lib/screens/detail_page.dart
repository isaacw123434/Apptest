import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/emission_utils.dart';
import '../utils/time_utils.dart';
import '../utils/icon_utils.dart';
import '../utils/app_colors.dart';
import '../widgets/detail/leg_selector_modal.dart';
import '../widgets/scale_on_press.dart';

class DetailPage extends StatefulWidget {
  final JourneyResult? journeyResult;
  final ApiService? apiService;
  final String? routeId;
  final Map<String, bool>? selectedModes;

  const DetailPage({
    super.key,
    this.journeyResult,
    this.apiService,
    this.routeId,
    this.selectedModes,
  });

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final Distance _distance = const Distance();
  late final ApiService _apiService;
  InitData? _initData;
  MapController? _mapController;
  final DraggableScrollableController _sheetController = DraggableScrollableController();
  ScrollController? _innerScrollController;
  List<Polyline> _polylines = [];
  List<Marker> _markers = [];
  JourneyResult? _currentResult;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _mapController = MapController();
    if (widget.journeyResult != null) {
      _currentResult = widget.journeyResult;
      _updatePolylines();
    }
    _fetchData();
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchInitData(routeId: widget.routeId);
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
    List<Marker> markers = [];

    // --- Collect All Segments ---
    List<Segment> allSegments = [];
    allSegments.addAll(result.leg1.segments);
    if (_initData != null) {
      allSegments.addAll(_initData!.segmentOptions.mainLeg.segments);
    }
    allSegments.addAll(result.leg3.segments);

    // --- Generate Polylines ---
    void addPolyline(Segment seg) {
        if (seg.subSegments != null && seg.subSegments!.isNotEmpty) {
            for (var sub in seg.subSegments!) {
                addPolyline(sub);
            }
            return;
        }

        if (seg.path != null && seg.path!.isNotEmpty) {
            // Filter out invalid coordinates
            final validPoints = seg.path!.where((p) => p.latitude.abs() <= 90).toList();
            if (validPoints.isNotEmpty) {
                final points = validPoints.map((p) => LatLng(p.latitude, p.longitude)).toList();
                final isWalk = seg.mode.toLowerCase() == 'walk' || seg.iconId == 'footprints';

                lines.add(Polyline(
                    points: points,
                    color: _parseColor(seg.lineColor),
                    strokeWidth: 6.0,
                    pattern: isWalk ? const StrokePattern.dotted() : const StrokePattern.solid(),
                ));
            }
        }
    }

    for (var seg in allSegments) {
        addPolyline(seg);
    }

    // Fallback if no lines generated yet, try mock path
    if (lines.isEmpty && _initData != null && _initData!.mockPath.isNotEmpty) {
       final mockPoints = _initData!.mockPath.map((p) => LatLng(p.latitude, p.longitude)).toList();
       lines.add(Polyline(
         points: mockPoints,
         color: Colors.blue,
         strokeWidth: 4.0,
       ));
    }

    // --- Generate Markers ---
    // Flatten segments for markers
    List<Segment> flattened = [];
    void flatten(Segment s) {
        if (s.subSegments != null && s.subSegments!.isNotEmpty) {
            for (var sub in s.subSegments!) {
              flatten(sub);
            }
        } else {
            flattened.add(s);
        }
    }
    for (var s in allSegments) {
      flatten(s);
    }

    if (flattened.isNotEmpty) {
      // Start Marker
      final startSeg = flattened.first;
      if (startSeg.path != null && startSeg.path!.isNotEmpty) {
        markers.add(Marker(
          point: LatLng(startSeg.path!.first.latitude, startSeg.path!.first.longitude),
          width: 24,
          height: 24,
          child: _buildMarkerWidget(isStart: true),
        ));
      }

      // End Marker
      final endSeg = flattened.last;
      if (endSeg.path != null && endSeg.path!.isNotEmpty) {
        markers.add(Marker(
          point: LatLng(endSeg.path!.last.latitude, endSeg.path!.last.longitude),
          width: 24,
          height: 24,
          child: _buildMarkerWidget(isEnd: true),
        ));
      }

      // Mode Change Nodes
      for (int i = 0; i < flattened.length - 1; i++) {
        final current = flattened[i];

        if (current.path != null && current.path!.isNotEmpty) {
            markers.add(Marker(
              point: LatLng(current.path!.last.latitude, current.path!.last.longitude),
              width: 12,
              height: 12,
              child: _buildMarkerWidget(),
            ));
        }
      }

      // Intermediate Stops (small nodes)
      for (var seg in flattened) {
        if (seg.stopPoints != null && seg.stopPoints!.isNotEmpty) {
          for (var point in seg.stopPoints!) {
            markers.add(Marker(
              point: point,
              width: 8,
              height: 8,
              child: _buildStopMarkerWidget(),
            ));
          }
        }
      }
    }

    setState(() {
      _polylines = lines;
      _markers = markers;
    });

    if (_isMapReady) {
      // Delay to ensure map is fully rendered before fitting bounds
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _zoomToFit();
      });
    }
  }

  void _zoomToSegment(Segment segment) {
    if (!mounted || _mapController == null || segment.path == null || segment.path!.isEmpty) return;

    final points = segment.path!;
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Animate sheet down to reveal map
    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Reset scroll position to top
    if (_innerScrollController != null && _innerScrollController!.hasClients) {
      _innerScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    // Fit camera
    // Calculate padding to account for bottom sheet (25% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.25;

    _mapController!.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: EdgeInsets.only(
        top: 50,
        left: 50,
        right: 50,
        bottom: bottomPadding + 50,
      ),
    ));
  }

  Widget _buildStopMarkerWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black54, width: 1.5),
      ),
    );
  }

  Widget _buildMarkerWidget({bool isStart = false, bool isEnd = false}) {
    if (isStart) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF10B981), // Emerald 500
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
             BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ]
        ),
        child: const Icon(LucideIcons.play, size: 12, color: Colors.white),
      );
    } else if (isEnd) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate 900
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
             BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
          ]
        ),
        child: const Icon(LucideIcons.flag, size: 12, color: Colors.white),
      );
    } else {
      // Node
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF0F172A), width: 2),
        ),
      );
    }
  }

  Color _parseColor(String lineColor) {
    try {
      return Color(int.parse(lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF4F46E5); // Brand Blue as fallback
    }
  }

  Map<String, List<Leg>> _groupLegsByStation(List<Leg> options) {
    final Map<String, List<Leg>> groupedLegs = {};
    for (var option in options) {
      String suffix = _getStationSuffix(option.label);
      if (!groupedLegs.containsKey(suffix)) {
        groupedLegs[suffix] = [];
      }
      groupedLegs[suffix]!.add(option);
    }
    return groupedLegs;
  }

  String _getStationSuffix(String label) {
    final RegExp pattern = RegExp(r'^(Walk|Cycle|Uber|Drive|Bus|Taxi)(.*)', caseSensitive: false);
    final match = pattern.firstMatch(label);
    if (match != null && match.groupCount >= 2) {
      return match.group(2)!.trim();
    }
    return label;
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
            text: savings > 0 ? 'Saves $savingsPercent% CO₂e vs driving' : null
        ),
      );

      _updatePolylines();
    });
  }

  String? _getSegmentDestination(Segment segment) {
    if (segment.subSegments != null && segment.subSegments!.isNotEmpty) {
      return _getSegmentDestination(segment.subSegments!.last);
    }
    return segment.to;
  }

  List<Leg> _filterLegs(List<Leg> options, String legType, {Leg? currentLeg}) {
    if (_initData == null) return options;
    final mainLeg = _initData!.segmentOptions.mainLeg;

    String? anchorStation;

    // Smart Filtering for Route 2 (or empty main leg)
    if (widget.routeId == 'route2' && mainLeg.segments.isEmpty && currentLeg != null && currentLeg.segments.isNotEmpty) {
       if (legType == 'firstMile') {
           // Find where the access part ends (the anchor)
           // Typically first segment is access
           try {
              final accessSeg = currentLeg.segments.firstWhere((s) =>
                  s.mode.toLowerCase() != 'wait' && s.label != 'Transfer',
                  orElse: () => currentLeg.segments.first
              );
              anchorStation = _getSegmentDestination(accessSeg);
           } catch(e) {
              anchorStation = null;
           }

           if (anchorStation == null) return options;

           return options.where((leg) {
                if (leg.segments.isEmpty) return false;
                // Check if option's access segment ends at same anchor
                try {
                    final optAccessSeg = leg.segments.firstWhere((s) =>
                        s.mode.toLowerCase() != 'wait' && s.label != 'Transfer',
                        orElse: () => leg.segments.first
                    );
                    return _getSegmentDestination(optAccessSeg) == anchorStation;
                } catch (e) {
                    return false;
                }
           }).toList();
       }
       // Only First Mile logic requested for Route 2 specifically, but Last Mile could be symmetric.
       // For Route 2 leg3 is empty so it won't matter.
       return options;
    }

    if (mainLeg.segments.isEmpty) return options;

    if (legType == 'firstMile') {
       anchorStation = mainLeg.segments.first.from;
       if (anchorStation == null) return options;

       return options.where((leg) {
           if (leg.segments.isEmpty) return false;
           return _getSegmentDestination(leg.segments.last) == anchorStation;
       }).toList();
    } else if (legType == 'lastMile') {
       anchorStation = mainLeg.segments.last.to;
       if (anchorStation == null) return options;

       return options.where((leg) {
           if (leg.segments.isEmpty) return false;
           return leg.segments.first.from == anchorStation;
       }).toList();
    }
    return options;
  }

  void _showAccessEdit(Leg currentLeg, String legType) {
    if (_initData == null) return;

    List<Leg> allOptions = legType == 'firstMile'
        ? _initData!.segmentOptions.firstMile
        : _initData!.segmentOptions.lastMile;

    // Filter by anchor station
    List<Leg> filteredOptions = _filterLegs(allOptions, legType, currentLeg: currentLeg);


    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return LegSelectorModal(
          options: filteredOptions,
          currentLeg: currentLeg,
          title: 'Access Options',
          onSelect: (Leg selectedLeg) {
            _updateLeg(legType, selectedLeg);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showTrainEdit(Leg currentLeg, String legType) {
    if (_initData == null) return;

    List<Leg> allOptions = legType == 'firstMile'
        ? _initData!.segmentOptions.firstMile
        : _initData!.segmentOptions.lastMile;

    // Filter by anchor station
    allOptions = _filterLegs(allOptions, legType, currentLeg: currentLeg);

    Map<String, List<Leg>> grouped = _groupLegsByStation(allOptions);
    // Determine current access mode from first segment
    String currentAccessMode = currentLeg.segments.isNotEmpty ? currentLeg.segments.first.mode : 'walk';

    // Pick representatives
    List<Leg> representatives = [];
    grouped.forEach((suffix, legs) {
      // Find leg matching current access mode
      Leg? match;
      try {
         match = legs.firstWhere((leg) {
             if (leg.segments.isEmpty) return false;
             return leg.segments.first.mode == currentAccessMode;
         });
      } catch (e) {
         match = null;
      }

      if (match != null) {
          representatives.add(match);
      } else {
          // Fallback: Lowest Cost
          legs.sort((a, b) => a.cost.compareTo(b.cost));
          representatives.add(legs.first);
      }
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return LegSelectorModal(
          options: representatives,
          currentLeg: currentLeg,
          title: 'Choose Route',
          labelBuilder: (leg) {
             // Try to construct "FromStation to ToStation"
             // Find train segment
             Segment? trainSeg;
             try {
                trainSeg = leg.segments.firstWhere((s) => s.iconId == 'train');
             } catch (e) {
                trainSeg = null;
             }

             if (trainSeg != null && trainSeg.from != null && trainSeg.to != null) {
                 return '${trainSeg.from} to ${trainSeg.to}';
             }

             // Fallback: parse label if "Drive to X + Train"
             final match = RegExp(r'to\s+(.*?)\s+\+\s+Train', caseSensitive: false).firstMatch(leg.label);
             if (match != null) {
                 return '${match.group(1)} to Leeds'; // Assume Leeds if implicit
             }

             return leg.label;
          },
          onSelect: (Leg selectedLeg) {
            _updateLeg(legType, selectedLeg);
            Navigator.pop(context);
          },
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
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
              onMapReady: () {
                _isMapReady = true;
                // Delay to ensure map is fully rendered before fitting bounds
                Future.delayed(const Duration(milliseconds: 200), () {
                  if (mounted) _zoomToFit();
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              PolylineLayer(
                polylines: _polylines,
              ),
              MarkerLayer(
                markers: _markers,
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

          // 2. Sliding Sheet
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.25,
            minChildSize: 0.25,
            maxChildSize: 0.9,
            snap: true,
            snapSizes: const [0.25, 0.35, 0.9],
            builder: (context, scrollController) {
              _innerScrollController = scrollController;
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
                                            ? '${result.emissions.val.toStringAsFixed(2)} kg CO₂e'
                                            : 'Low CO₂e',
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
            child: ScaleOnPress(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(LucideIcons.heart),
                  label: const Text('Save Route'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
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
    void addSegments(Leg leg, String legType) {
      final bool canEdit = legType != 'mainLeg';
      final segments = leg.segments;

      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isFirst = i == 0;

        // Determine extra details (moved up to avoid unused variable warning if unused below)
        String? extraDetails;
        if (seg.iconId == 'train' && leg.platform != null) {
          extraDetails = 'Platform ${leg.platform}';
        } else if (seg.iconId == 'bus' && leg.nextBusIn != null) {
          extraDetails = 'Bus every ${formatDuration(leg.nextBusIn!)}';
        } else if ((seg.iconId == 'car' || seg.mode == 'taxi') && leg.waitTime != null) {
          extraDetails = 'Est wait: ${formatDuration(leg.waitTime!)}';
        } else if (seg.iconId == 'bike' && leg.desc != null) {
          extraDetails = leg.desc;
        } else if (seg.detail != null && seg.detail!.isNotEmpty) {
          extraDetails = seg.detail;
        }

        // Check for Transfer
        if (seg.mode == 'wait' && seg.label == 'Transfer') {
             // 10 mins transfer text
             children.add(_buildTransferSegment(seg));
             currentMinutes += seg.time;
             continue; // Skip building regular connection and node
        }

        // --- ACCESS MERGE DETECTION ---
        // Merge [Walk/Wait... -> Ride] into MultiSegmentConnection
        // But only if the Ride is NOT a Train that triggers a Train Merge
        bool isWalkOrWait(Segment s) => (s.mode.toLowerCase() == 'walk' || s.iconId == 'footprints') || (s.mode == 'wait' && s.label != 'Transfer');
        bool isRide(Segment s) => !isWalkOrWait(s) && !(s.mode == 'wait' && s.label == 'Transfer');

        // --- TRAIN MERGE DETECTION (New) ---
        bool isTrain(Segment s) => s.iconId == 'train';
        if (isTrain(seg) && i + 1 < segments.length) {
             final nextSeg = segments[i+1];
             if (isTrain(nextSeg)) {
                 children.add(_buildMergedSegmentConnection(
                    seg1: seg,
                    seg2: nextSeg,
                    changeLabel: 'Change',
                    waitTime: 0, // Wait time implicit in segments if split? Or need to sum up?
                    // Actually, if we just split them in JSON, waitTime is lost unless we added a wait segment.
                    // But typically wait time is small or 0 for direct connections.
                    dist1: seg.distance,
                    dist2: nextSeg.distance,
                    extraDetails1: seg.detail ?? extraDetails,
                    // Ensure main leg (train merge) is not editable
                    isEditable: canEdit && legType != 'mainLeg',
                    onEdit: () => _showTrainEdit(leg, legType),
                    onTap: () => _zoomToSegment(seg) // Zoom to first? Or group?
                 ));
                 currentMinutes += seg.time + nextSeg.time;
                 if (seg.waitTime != null) currentMinutes += seg.waitTime!;
                 if (nextSeg.waitTime != null) currentMinutes += nextSeg.waitTime!;

                 i++; // Skip next

                 // Node logic after the pair?
                 // The standard loop adds a node after 'i' if i < length-1.
                 // Here we consumed i and i+1.
                 // We need to add a node after i+1 if i+1 < length-1.

                 if (i < segments.length - 1) {
                     // Next visible is segments[i+1] (which is the one we just consumed as 2nd part)
                     // Wait, i is now index of 2nd part.
                     // We need node between 2nd part and 3rd part.

                     // Copied node logic from below:
                      String nodeTitle = segments[i].to ?? 'Stop';
                      Color prevColor = _parseColor(segments[i].lineColor);

                      final nextVisible = segments[i + 1];
                      Color nextColor = _parseColor(nextVisible.lineColor);
                      if (nextVisible.subSegments != null && nextVisible.subSegments!.isNotEmpty) {
                           nextColor = _parseColor(nextVisible.subSegments!.first.lineColor);
                      }

                       children.add(_buildNode(
                          nodeTitle,
                          _formatMinutes(currentMinutes),
                          prevColor: prevColor,
                          nextColor: nextColor));
                 }

                 continue;
             }
        }

        if (isWalkOrWait(seg) && (legType == 'firstMile' || legType == 'lastMile')) {
             int k = i + 1;
             while (k < segments.length && isWalkOrWait(segments[k])) {
                 k++;
             }

             if (k < segments.length) {
                 final nextSeg = segments[k];
                 if (isRide(nextSeg)) {
                      // Candidate for merge: segments[i...k]
                      bool preventMerge = false;
                      // Check if nextSeg is Train and Triggers Merge (Look ahead)
                      if (nextSeg.iconId == 'train') {
                           int lookAheadIndex = k + 1;
                           int tempIndex = lookAheadIndex;
                           Segment? nextTrainSeg;
                           if (tempIndex < segments.length) {
                               Segment? checkSeg = segments[tempIndex];
                               // Skip walk/transfer logic similar to train merge check
                               if (checkSeg.mode == 'walk' || checkSeg.iconId == 'footprints') {
                                   tempIndex++;
                                   if (tempIndex < segments.length) {
                                       checkSeg = segments[tempIndex];
                                   } else {
                                       checkSeg = null;
                                   }
                               }
                               if (checkSeg != null && checkSeg.iconId == 'train') {
                                   nextTrainSeg = checkSeg;
                               }
                           }

                           if (nextTrainSeg != null) {
                               preventMerge = true;
                           }
                      }

                      if (!preventMerge) {
                            // --- SCAN FOR TRAILING WALKS ---
                            int endIdx = k + 1;
                            while (endIdx < segments.length && isWalkOrWait(segments[endIdx])) {
                                endIdx++;
                            }
                            // -------------------------------

                            List<Segment> mergeGroup = segments.sublist(i, endIdx);

                           int totalTime = 0;
                           for(var s in mergeGroup) {
                               totalTime += s.time + (s.waitTime ?? 0);
                           }

                           children.add(_buildMultiSegmentConnection(
                               segments: mergeGroup,
                               isEditable: canEdit,
                               onEdit: () {
                                  if (mergeGroup.any((s) => s.iconId == 'train' || _isParkAndRideBus(s))) {
                                    _showTrainEdit(leg, legType);
                                  } else {
                                    _showAccessEdit(leg, legType);
                                  }
                               },
                               onTap: () => _zoomToSegments(mergeGroup),
                           ));

                           currentMinutes += totalTime;

                           // Add Node if needed (if not last segment of whole leg)
                            if (endIdx < segments.length) {
                               Segment lastSeg = mergeGroup.last;
                                Segment nextVis = segments[endIdx];
                               children.add(_buildNode(
                                  lastSeg.to ?? 'Stop',
                                  _formatMinutes(currentMinutes),
                                  prevColor: _parseColor(lastSeg.lineColor),
                                  nextColor: _parseColor(nextVis.lineColor)
                               ));
                           }

                            i = endIdx - 1; // Loop increments i, so point to last consumed
                           continue;
                      }
                 }
             }
        }

        // --- GROUP DETECTION ---
        if (seg.subSegments != null && seg.subSegments!.isNotEmpty) {
            // It's a group (Access or Train)
            bool isTrainGroup = seg.mode == 'train_group';

            if (isTrainGroup) {
                // Train Merge
                // Expect 2 subsegments
                if (seg.subSegments!.length >= 2) {
                    Segment s1 = seg.subSegments![0];
                    Segment s2 = seg.subSegments![1];
                    // s1 might need details from parent if populated in previous step
                    // But details should be on subsegments if process_routes did its job.
                    // Process_routes populated `detail` on subsegments BEFORE grouping.

                    // Wait time is on group seg
                    children.add(_buildMergedSegmentConnection(
                        seg1: s1,
                        seg2: s2,
                        changeLabel: seg.detail ?? 'Change',
                        waitTime: seg.waitTime ?? 0,
                        dist1: s1.distance,
                        dist2: s2.distance,
                        extraDetails1: s1.detail ?? extraDetails, // Use calculated details if python didn't populate
                        // Ensure main leg (train merge) is not editable
                        isEditable: canEdit && legType != 'mainLeg',
                        onEdit: () => _showTrainEdit(leg, legType),
                        onTap: () => _zoomToSegment(seg)
                    ));
                }
            } else {
                // Access Group
                children.add(_buildMultiSegmentConnection(
                    segments: seg.subSegments!,
                    isEditable: canEdit,
                    onEdit: () {
                        if (seg.subSegments!.any((s) => s.iconId == 'train')) {
                            _showTrainEdit(leg, legType);
                        } else {
                            _showAccessEdit(leg, legType);
                        }
                    },
                    onTap: () => _zoomToSegments(seg.subSegments!)
                ));
            }

            currentMinutes += seg.time;
            if (seg.waitTime != null) currentMinutes += seg.waitTime!;

        } else {
            // Single Segment

            // Calculate Distance (if not present)
            double? distance = seg.distance;
            if (distance == null && seg.path != null && seg.path!.isNotEmpty) {
                double totalMeters = 0;
                for (int j = 0; j < seg.path!.length - 1; j++) {
                    totalMeters += _distance.as(LengthUnit.Meter, seg.path![j], seg.path![j + 1]);
                }
                distance = totalMeters / 1609.34;
            }

            // Disable editing for core segments in Route 2
            bool isCoreSegment = widget.routeId == 'route2' && (seg.iconId == 'train' || _isParkAndRideBus(seg));

            children.add(_buildSegmentConnection(
                segment: seg,
                isEditable: !isCoreSegment && canEdit && (isFirst || seg.iconId == 'train' || _isParkAndRideBus(seg)),
                onEdit: () {
                    if (seg.iconId == 'train' || _isParkAndRideBus(seg)) {
                        _showTrainEdit(leg, legType);
                    } else {
                        _showAccessEdit(leg, legType);
                    }
                },
                onTap: () => _zoomToSegment(seg),
                distance: distance,
                extraDetails: seg.detail ?? extraDetails, // Use local extraDetails if seg.detail is null
                isDriveToStation: legType == 'firstMile' && seg.label == 'Drive' && !_isParkAndRideDestination(seg),
            ));

            currentMinutes += seg.time;
            if (seg.waitTime != null) {
                currentMinutes += seg.waitTime!;
            }
        }

        // Node Logic
        if (i < segments.length - 1) {
          String nodeTitle = segments[i].to ?? 'Stop';
          Color prevColor = _parseColor(segments[i].lineColor);

          // Use last subsegment info if group
          if (segments[i].subSegments != null && segments[i].subSegments!.isNotEmpty) {
              nodeTitle = segments[i].subSegments!.last.to ?? 'Stop';
              prevColor = _parseColor(segments[i].subSegments!.last.lineColor);
          }

          if (i + 1 < segments.length) {
               final nextVisible = segments[i + 1];
               Color nextColor = _parseColor(nextVisible.lineColor);
               if (nextVisible.subSegments != null && nextVisible.subSegments!.isNotEmpty) {
                   nextColor = _parseColor(nextVisible.subSegments!.first.lineColor);
               }

               children.add(_buildNode(
                  nodeTitle,
                  _formatMinutes(currentMinutes),
                  prevColor: prevColor,
                  nextColor: nextColor));
          }
        }
      }
    }

    // --- Start Node ---
    Color leg1FirstColor = _parseColor(result.leg1.segments.isNotEmpty ? result.leg1.segments.first.lineColor : '#000000');
    String startTitle = 'Start Journey';
    if (result.leg1.segments.isNotEmpty && result.leg1.segments.first.from != null) {
      startTitle = result.leg1.segments.first.from!;
    }
    children.add(_buildNode(startTitle, _formatMinutes(currentMinutes),
        isStart: true, nextColor: leg1FirstColor));

    // --- Leg 1 ---
    addSegments(result.leg1, 'firstMile');

    // --- Check Main Leg ---
    bool hasMainLeg = _initData!.segmentOptions.mainLeg.segments.isNotEmpty;

    if (hasMainLeg) {
      // --- Leeds Node ---
      // Time range: Arrival - Depart
      String leedsTimeStr =
          '${_formatMinutes(currentMinutes)} - ${_formatMinutes(currentMinutes + result.buffer)}';
      Color leg1LastColor = result.leg1.segments.isNotEmpty ? _parseColor(result.leg1.segments.last.lineColor) : Colors.grey;
      Color mainLegColor = _parseColor(_initData!.segmentOptions.mainLeg.segments.first.lineColor);

      children.add(_buildNode('Leeds Station', leedsTimeStr,
          prevColor: leg1LastColor, nextColor: mainLegColor));
      currentMinutes += result.buffer;

      // --- Main Leg ---
      addSegments(_initData!.segmentOptions.mainLeg, 'mainLeg');

      // --- Loughborough Node ---
      Color mainLegLastColor =
          _parseColor(_initData!.segmentOptions.mainLeg.segments.last.lineColor);
      Color leg3FirstColor = result.leg3.segments.isNotEmpty ? _parseColor(result.leg3.segments.first.lineColor) : Colors.grey;

      children.add(_buildNode('Loughborough Station', _formatMinutes(currentMinutes),
          prevColor: mainLegLastColor, nextColor: leg3FirstColor));
    } else {
      // --- Interchange Node (Direct Connection) ---
      // Fix: Don't show interchange node if leg3 is empty (Route 2 P&R)
      if (result.leg3.id != 'empty_last_mile') {
        Color leg1LastColor = result.leg1.segments.isNotEmpty ? _parseColor(result.leg1.segments.last.lineColor) : Colors.grey;
        Color leg3FirstColor = result.leg3.segments.isNotEmpty ? _parseColor(result.leg3.segments.first.lineColor) : Colors.grey;

        // Try to determine interchange name
        String interchangeName = 'Interchange';
        if (result.leg1.segments.isNotEmpty && result.leg1.segments.last.to != null) {
           interchangeName = result.leg1.segments.last.to!;
        } else if (result.leg3.segments.isNotEmpty && result.leg3.segments.first.label.contains('Leeds')) {
           interchangeName = 'Leeds Station';
        }

        String timeStr = '${_formatMinutes(currentMinutes)} - ${_formatMinutes(currentMinutes + result.buffer)}';

        children.add(_buildNode(interchangeName, timeStr,
            prevColor: leg1LastColor, nextColor: leg3FirstColor));

        currentMinutes += result.buffer;
      }
    }

    // --- Leg 3 ---
    addSegments(result.leg3, 'lastMile');

    // --- End Node ---
    Color leg3LastColor = result.leg3.segments.isNotEmpty ? _parseColor(result.leg3.segments.last.lineColor) : Colors.grey;
    String endTitle = 'Arrive Destination';
    if (result.leg3.segments.isNotEmpty && result.leg3.segments.last.to != null) {
      endTitle = 'Arrive ${result.leg3.segments.last.to!}';
    } else if (result.leg3.id == 'empty_last_mile' && result.leg1.segments.isNotEmpty && result.leg1.segments.last.to != null) {
      // Fix: Fallback to leg1 destination if leg3 is empty (Route 2 P&R)
      endTitle = 'Arrive ${result.leg1.segments.last.to!}';
      // Also use leg1 color for connection to end node if leg3 is empty
      if (result.leg1.segments.isNotEmpty) {
         leg3LastColor = _parseColor(result.leg1.segments.last.lineColor);
      }
    }
    children.add(_buildNode(
      endTitle,
      _formatMinutes(currentMinutes),
      isEnd: true,
      prevColor: leg3LastColor
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  bool _isParkAndRideBus(Segment seg) {
    if (seg.iconId != 'bus') return false;
    final label = seg.label.toLowerCase();
    return label.contains('park & ride') || label.contains('p&r');
  }

  bool _isParkAndRideDestination(Segment seg) {
    if (seg.label != 'Drive') return false;
    if (seg.to != null) {
      final to = seg.to!.toLowerCase();
      return to.contains('park & ride') || to.contains('p&r');
    }
    return false;
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
            width: 24,
            child: Column(
              children: [
                // Line above (if not start)
                Expanded(
                  child: isStart
                      ? const SizedBox()
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                                width: 12,
                                height: double.infinity,
                                color: Colors.grey[200]),
                            Container(
                              width: 4,
                              height: double.infinity,
                              color: prevColor ?? Colors.grey[300],
                            ),
                          ],
                        ),
                ),

                // Dot
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isStart
                            ? const Color(0xFF0F172A)
                            : (prevColor ?? const Color(0xFF0F172A)),
                        width: 3),
                  ),
                ),

                // Line below (if not end)
                Expanded(
                  child: isEnd
                      ? const SizedBox()
                      : Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                                width: 12,
                                height: double.infinity,
                                color: Colors.grey[200]),
                            Container(
                              width: 4,
                              height: double.infinity,
                              color: nextColor ?? Colors.grey[300],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
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
    VoidCallback? onTap,
    double? distance,
    String? extraDetails,
    bool isDriveToStation = false,
  }) {
    // Prefer segment.distance if available
    final displayDistance = segment.distance ?? distance;
    final emission = segment.co2 ?? (displayDistance != null ? calculateEmission(displayDistance, segment.iconId) : 0.0);
    Color lineColor = _parseColor(segment.lineColor);

    // Calculate split costs if applicable
    double? drivingCost;
    double? parkingCost;
    if (isDriveToStation && displayDistance != null) {
      drivingCost = displayDistance * 0.45;
      parkingCost = segment.cost - drivingCost;
      // Ensure no negative values due to precision or if cost is 0
      if (parkingCost < 0) parkingCost = 0;
    }

    // FIX 1 & 2: The Grey Track & Thicker Line
    Widget verticalLine = Stack(
      alignment: Alignment.center,
      children: [
        // The Track (Background)
        Container(
          width: 12, // Wider than the color line
          height: double.infinity,
          color: Colors.grey[200], // Provides contrast for Neon Green
        ),
        // The Route Color (Foreground)
        Container(
          width: 4, // Thicker for visibility
          height: double.infinity,
          color: lineColor,
        ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Vertical Line
          SizedBox(width: 24, child: verticalLine), // Fixed width container
          const SizedBox(width: 16),
          // Content
          Expanded(
            child: GestureDetector(
              onTap: onTap,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // FIX 3: The Icon Halo
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: lineColor.withValues(alpha: 0.15), // The "Halo"
                          shape: BoxShape.circle,
                        ),
                        child: Icon(getIconData(segment.iconId) ?? LucideIcons.circle,
                            color: lineColor, // Keep icon solid
                            size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(segment.label,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              '${formatDuration(segment.time)}${displayDistance != null ? ' • ${displayDistance.toStringAsFixed(1)} miles' : ''}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            if (isDriveToStation && drivingCost != null && parkingCost != null) ...[
                               Text(
                                 'Driving cost: £${drivingCost.toStringAsFixed(2)}',
                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                               ),
                               Text(
                                 parkingCost == 0
                                     ? 'Parking cost: Free, but limited parking'
                                     : 'Parking cost (24 hours): £${parkingCost.toStringAsFixed(2)}',
                                 style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                               ),
                            ],
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
                            if (segment.numStops != null && segment.numStops! > 0) ...[
                              const SizedBox(height: 2),
                              Text(
                                '${segment.numStops} stops',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                            if (segment.stops != null && segment.stops!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              ...segment.stops!.map((stop) => Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 2),
                                  child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                            margin: const EdgeInsets.only(top: 5),
                                            width: 4,
                                            height: 4,
                                            decoration: const BoxDecoration(
                                                color: Colors.grey,
                                                shape: BoxShape.circle)),
                                        const SizedBox(width: 6),
                                        Expanded(
                                            child: Text(stop,
                                                style: const TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey))),
                                      ])))
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
                  if (segment.cost > 0 || displayDistance != null || emission > 0) ...[
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (segment.cost > 0)
                          Text(
                            '£${segment.cost.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                          )
                        else
                          const SizedBox(),
                        if (displayDistance != null || emission > 0)
                          Row(
                            children: [
                              const Icon(LucideIcons.leaf,
                                  size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${emission.toStringAsFixed(2)} kg CO₂e',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ]
                ],
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildTransferSegment(Segment segment) {
    Color lineColor = _parseColor(segment.lineColor);

    Widget verticalLine = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12,
          height: double.infinity,
          color: Colors.grey[200],
        ),
        Container(
          width: 4,
          height: double.infinity,
          color: lineColor,
        ),
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 24, child: verticalLine),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${formatDuration(segment.time)} transfer', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMergedSegmentConnection({
    required Segment seg1,
    required Segment seg2,
    required String changeLabel,
    required int waitTime,
    double? dist1,
    double? dist2,
    String? extraDetails1,
    bool isEditable = false,
    VoidCallback? onEdit,
    VoidCallback? onTap,
  }) {
    double totalCost = seg1.cost + seg2.cost;
    double totalCo2 = (seg1.co2 ?? 0) + (seg2.co2 ?? 0);
    // If co2 is missing, estimate?
    if (seg1.co2 == null && dist1 != null) totalCo2 += calculateEmission(dist1, seg1.iconId);
    if (seg2.co2 == null && dist2 != null) totalCo2 += calculateEmission(dist2, seg2.iconId);

    Color color1 = _parseColor(seg1.lineColor);
    Color color2 = _parseColor(seg2.lineColor);

    Widget verticalLine = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12,
          height: double.infinity,
          color: Colors.grey[200],
        ),
        Column(
          children: [
             Expanded(child: Container(width: 4, color: color1)),
             Expanded(child: Container(width: 4, color: color2)),
          ],
        )
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 24, child: verticalLine),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Seg 1
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color1.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(getIconData(seg1.iconId) ?? LucideIcons.circle, color: color1, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(seg1.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${formatDuration(seg1.time)}${dist1 != null ? ' • ${dist1.toStringAsFixed(1)} miles' : ''}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                        if (extraDetails1 != null) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            extraDetails1,
                                            style: const TextStyle(fontSize: 11, color: Colors.blueGrey, fontStyle: FontStyle.italic),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Divider / Change
                              Padding(
                                padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                                child: Row(
                                  children: [
                                    const Icon(LucideIcons.arrowDown, size: 12, color: Colors.grey),
                                    const SizedBox(width: 8),
                                    Text(
                                       '$changeLabel (${waitTime > 0 ? formatDuration(waitTime) : 'Immediate'})',
                                       style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                                    ),
                                  ],
                                ),
                              ),

                              // Seg 2
                              Row(
                                children: [
                                   Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: color2.withValues(alpha: 0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(getIconData(seg2.iconId) ?? LucideIcons.circle, color: color2, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(seg2.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        Text(
                                          '${formatDuration(seg2.time)}${dist2 != null ? ' • ${dist2.toStringAsFixed(1)} miles' : ''}',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (isEditable && onEdit != null)
                          Center(
                            child: TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(LucideIcons.pencil, size: 14),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4F46E5),
                                textStyle:
                                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 4),

                    // Totals
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         if (totalCost > 0)
                           Text(
                             '£${totalCost.toStringAsFixed(2)}',
                             style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
                           ),
                         if (totalCo2 > 0)
                           Row(
                            children: [
                              const Icon(LucideIcons.leaf, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                '${totalCo2.toStringAsFixed(2)} kg CO₂e',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _zoomToFit() {
    if (!mounted) return;
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

    // Calculate padding to account for bottom sheet (25% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.25;

    _mapController!.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: EdgeInsets.only(
        top: 50,
        left: 50,
        right: 50,
        bottom: bottomPadding + 50,
      ),
    ));
  }

  void _zoomToSegments(List<Segment> segments) {
    if (!mounted || _mapController == null || segments.isEmpty) return;

    double minLat = 90.0;
    double maxLat = -90.0;
    double minLng = 180.0;
    double maxLng = -180.0;
    bool hasPoints = false;

    for (var seg in segments) {
      if (seg.path != null && seg.path!.isNotEmpty) {
        for (var point in seg.path!) {
          if (point.latitude < minLat) minLat = point.latitude;
          if (point.latitude > maxLat) maxLat = point.latitude;
          if (point.longitude < minLng) minLng = point.longitude;
          if (point.longitude > maxLng) maxLng = point.longitude;
          hasPoints = true;
        }
      }
    }

    if (!hasPoints) return;

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    if (_sheetController.isAttached) {
      _sheetController.animateTo(
        0.25,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    if (_innerScrollController != null && _innerScrollController!.hasClients) {
      _innerScrollController!.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }

    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.25;

    _mapController!.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: EdgeInsets.only(
        top: 50,
        left: 50,
        right: 50,
        bottom: bottomPadding + 50,
      ),
    ));
  }

  Widget _buildMultiSegmentConnection({
    required List<Segment> segments,
    required bool isEditable,
    VoidCallback? onEdit,
    VoidCallback? onTap,
  }) {
    double totalCost = 0;
    double totalCo2 = 0;

    List<Widget> contentChildren = [];
    List<Widget> lineChildren = [];

    for (int i = 0; i < segments.length; i++) {
      final seg = segments[i];
      totalCost += seg.cost;

      double? dist;
      if (seg.path != null && seg.path!.isNotEmpty) {
        double totalMeters = 0;
        for (int j = 0; j < seg.path!.length - 1; j++) {
          totalMeters +=
              _distance.as(LengthUnit.Meter, seg.path![j], seg.path![j + 1]);
        }
        dist = totalMeters / 1609.34;
      }

      double segCo2 =
          seg.co2 ?? (dist != null ? calculateEmission(dist, seg.iconId) : 0.0);
      totalCo2 += segCo2;

      Color color = _parseColor(seg.lineColor);
      lineChildren.add(Expanded(child: Container(width: 4, color: color)));

      // Content Row
      contentChildren.add(Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(getIconData(seg.iconId) ?? LucideIcons.circle, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(seg.label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '${formatDuration(seg.time)}${dist != null ? ' • ${dist.toStringAsFixed(1)} miles' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (seg.detail != null)
                  Text(
                    seg.detail!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey,
                        fontStyle: FontStyle.italic),
                  ),
              ],
            ),
          ),
        ],
      ));

      // Divider / Connector (if not last)
      if (i < segments.length - 1) {
        contentChildren.add(Padding(
          padding: const EdgeInsets.only(left: 20, top: 4, bottom: 4),
          child: Row(
            children: [
              Container(width: 2, height: 16, color: Colors.grey[300]),
            ],
          ),
        ));
      }
    }

    Widget verticalLine = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 12,
          height: double.infinity,
          color: Colors.grey[200],
        ),
        Column(
          children: lineChildren,
        )
      ],
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 24, child: verticalLine),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: onTap,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: contentChildren,
                          ),
                        ),
                        if (isEditable && onEdit != null)
                          Center(
                            child: TextButton.icon(
                              onPressed: onEdit,
                              icon: const Icon(LucideIcons.pencil, size: 14),
                              label: const Text('Edit'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF4F46E5),
                                textStyle: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (totalCost > 0 || totalCo2 > 0) ...[
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (totalCost > 0)
                            Text(
                              '£${totalCost.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          if (totalCo2 > 0)
                            Row(
                              children: [
                                const Icon(LucideIcons.leaf,
                                    size: 12, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  '${totalCo2.toStringAsFixed(2)} kg CO₂e',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

