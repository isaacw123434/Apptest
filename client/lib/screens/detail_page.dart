import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/emission_utils.dart';

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
    for (var seg in allSegments) {
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
    if (allSegments.isNotEmpty) {
      // Start Marker
      final startSeg = allSegments.first;
      if (startSeg.path != null && startSeg.path!.isNotEmpty) {
        markers.add(Marker(
          point: LatLng(startSeg.path!.first.latitude, startSeg.path!.first.longitude),
          width: 24,
          height: 24,
          child: _buildMarkerWidget(isStart: true),
        ));
      }

      // End Marker
      final endSeg = allSegments.last;
      if (endSeg.path != null && endSeg.path!.isNotEmpty) {
        markers.add(Marker(
          point: LatLng(endSeg.path!.last.latitude, endSeg.path!.last.longitude),
          width: 24,
          height: 24,
          child: _buildMarkerWidget(isEnd: true),
        ));
      }

      // Mode Change Nodes
      for (int i = 0; i < allSegments.length - 1; i++) {
        final current = allSegments[i];

        if (current.path != null && current.path!.isNotEmpty) {
            markers.add(Marker(
              point: LatLng(current.path!.last.latitude, current.path!.last.longitude),
              width: 12,
              height: 12,
              child: _buildMarkerWidget(),
            ));
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

  String _getModeKey(Leg leg) {
    if (leg.iconId == 'train') return 'train';
    if (leg.iconId == 'bus') return 'bus';
    if (leg.iconId == 'bike') return 'bike';
    if (leg.iconId == 'car') {
      // Check label for taxi/uber vs drive
      if (leg.label.toLowerCase().contains('taxi') || leg.label.toLowerCase().contains('uber')) {
        return 'taxi';
      }
      return 'car';
    }
    return leg.iconId;
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
            text: savings > 0 ? 'Saves $savingsPercent% CO₂ vs driving' : null
        ),
      );

      _updatePolylines();
    });
  }

  void _showAccessEdit(Leg currentLeg, String legType) {
    if (_initData == null) return;

    List<Leg> allOptions = legType == 'firstMile'
        ? _initData!.segmentOptions.firstMile
        : _initData!.segmentOptions.lastMile;

    String currentSuffix = _getStationSuffix(currentLeg.label);

    // Filter options with same suffix
    List<Leg> filteredOptions = allOptions.where((leg) {
      return _getStationSuffix(leg.label) == currentSuffix;
    }).toList();

    // Filter by selected modes
    if (widget.selectedModes != null) {
      filteredOptions = filteredOptions.where((leg) {
        String key = _getModeKey(leg);
        if (widget.selectedModes!.containsKey(key)) {
          return widget.selectedModes![key]!;
        }
        return true;
      }).toList();
    }

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

    // Filter by selected modes
    if (widget.selectedModes != null) {
      allOptions = allOptions.where((leg) {
        String key = _getModeKey(leg);
        if (widget.selectedModes!.containsKey(key)) {
          return widget.selectedModes![key]!;
        }
        return true;
      }).toList();
    }

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
            initialChildSize: 0.35,
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
    void addSegments(Leg leg, String legType) {
      final bool canEdit = legType != 'mainLeg';
      final segments = leg.segments;

      for (int i = 0; i < segments.length; i++) {
        final seg = segments[i];
        final isFirst = i == 0;

        // Check for Transfer
        if (seg.mode == 'wait' && seg.label == 'Transfer') {
             // 10 mins transfer text
             children.add(_buildTransferSegment(seg));
             currentMinutes += seg.time;
             continue; // Skip building regular connection and node
        }

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
        } else if (seg.detail != null && seg.detail!.isNotEmpty) {
          extraDetails = seg.detail;
        }

        // --- MERGE DETECTION START ---
        bool merged = false;
        if (seg.iconId == 'train') {
             // Look ahead for next train
             // Simplified logic: if next is train, merge.
             // Pre-processing handled filtered walks and wait times.

             int lookAheadIndex = i + 1;
             int accumulatedWaitTime = 0;
             Segment? nextTrainSeg;

             if (lookAheadIndex < segments.length) {
                 Segment? checkSeg = segments[lookAheadIndex];

                 // If it's a walk/transfer, treat it as wait time and look further
                 if (checkSeg.mode == 'walk' || checkSeg.iconId == 'footprints') {
                     accumulatedWaitTime += checkSeg.time;
                     lookAheadIndex++;
                     if (lookAheadIndex < segments.length) {
                         checkSeg = segments[lookAheadIndex];
                     } else {
                         // End of list, no next train
                         checkSeg = null;
                     }
                 }

                 if (checkSeg != null && checkSeg.iconId == 'train') {
                     nextTrainSeg = checkSeg;
                 }
             }

             if (nextTrainSeg != null) {
                 var nextSeg = nextTrainSeg;
                 // Merge detected
                 merged = true;

                 String changeLabel = 'Change at ${seg.to ?? 'Station'}';

                 // Use the waitTime carried over from pre-processing if available
                 // PLUS any accumulated time from walk segments
                 int waitTime = (nextSeg.waitTime ?? 0) + accumulatedWaitTime;

                 // Calculate distances for merging
                 double? dist1 = distance;
                 double? dist2;
                 if (nextSeg.path != null && nextSeg.path!.isNotEmpty) {
                   double totalMeters = 0;
                   for (int j = 0; j < nextSeg.path!.length - 1; j++) {
                     totalMeters += _distance.as(LengthUnit.Meter, nextSeg.path![j], nextSeg.path![j + 1]);
                   }
                   dist2 = totalMeters / 1609.34;
                 }

                 children.add(_buildMergedSegmentConnection(
                   seg1: seg,
                   seg2: nextSeg,
                   changeLabel: changeLabel,
                   waitTime: waitTime,
                   dist1: dist1,
                   dist2: dist2,
                   extraDetails1: extraDetails,
                   isEditable: canEdit,
                   onEdit: () => _showTrainEdit(leg, legType),
                   onTap: () {
                     _zoomToSegment(seg);
                   }
                 ));

                 currentMinutes += seg.time + waitTime + nextSeg.time;

                 // Update index to skip handled segments
                 i = lookAheadIndex;
             }
        }
        // --- MERGE DETECTION END ---

        if (!merged) {
          children.add(_buildSegmentConnection(
            segment: seg,
            isEditable: canEdit && (isFirst || seg.iconId == 'train'),
            onEdit: () {
              if (seg.iconId == 'train') {
                _showTrainEdit(leg, legType);
              } else {
                _showAccessEdit(leg, legType);
              }
            },
            onTap: () => _zoomToSegment(seg),
            distance: distance,
            extraDetails: extraDetails,
            isDriveToStation: legType == 'firstMile' && seg.label == 'Drive',
          ));

          currentMinutes += seg.time;
          if (seg.waitTime != null) {
             currentMinutes += seg.waitTime!;
          }
        }

        // Node Logic
        // We check loop index 'i' which might have been updated by merge logic
        if (i < segments.length - 1) {
          String nodeTitle = segments[i].to ?? 'Stop';
          Color prevColor = _parseColor(segments[i].lineColor);

          // Simply look at the next segment
          // If we merged, i points to the second train segment.
          // If next exists, it's just the next one in the list.

          if (i + 1 < segments.length) {
               final nextVisible = segments[i + 1];

               if (segments[i].iconId == 'train' && nextVisible.iconId == 'train') {
                   // This case should be handled by merge logic, but if missed:
                   nodeTitle = 'Change at ${segments[i].to ?? 'Station'}';
               }

               children.add(_buildNode(
                  nodeTitle,
                  _formatMinutes(currentMinutes),
                  prevColor: prevColor,
                  nextColor: _parseColor(nextVisible.lineColor)));
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
                    border: Border.all(color: const Color(0xFF0F172A), width: 3),
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
              child: Row(
                children: [
                  // FIX 3: The Icon Halo
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: lineColor.withValues(alpha: 0.15), // The "Halo"
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getIconData(segment.iconId),
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
                          '${segment.time} min${displayDistance != null ? ' • ${displayDistance.toStringAsFixed(1)} miles' : ''}',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        if (isDriveToStation && drivingCost != null && parkingCost != null) ...[
                           Text(
                             'Driving cost: £${drivingCost.toStringAsFixed(2)}',
                             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                           ),
                           Text(
                             parkingCost == 0
                                 ? 'Free, but limited parking'
                                 : 'Parking cost (24 hours): £${parkingCost.toStringAsFixed(2)}',
                             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                           ),
                        ] else if (segment.cost > 0)
                           Text(
                             '£${segment.cost.toStringAsFixed(2)}',
                             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
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
                  Text('${segment.time} mins transfer', style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)),
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
                          child: Icon(_getIconData(seg1.iconId), color: color1, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(seg1.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${seg1.time} min${dist1 != null ? ' • ${dist1.toStringAsFixed(1)} miles' : ''}',
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
                        if (isEditable && onEdit != null)
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

                    // Divider / Change
                    Padding(
                      padding: const EdgeInsets.only(left: 20, top: 8, bottom: 8),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.arrowDown, size: 12, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                             '$changeLabel (${waitTime > 0 ? '$waitTime mins' : 'Immediate'})',
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
                          child: Icon(_getIconData(seg2.iconId), color: color2, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(seg2.label, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                '${seg2.time} min${dist2 != null ? ' • ${dist2.toStringAsFixed(1)} miles' : ''}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
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
                                '${totalCo2.toStringAsFixed(2)} kg CO₂',
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

  IconData _getIconData(String iconId) {
    switch (iconId) {
      case 'train': return LucideIcons.train;
      case 'bus': return LucideIcons.bus;
      case 'car': return LucideIcons.car;
      case 'bike': return LucideIcons.bike;
      case 'footprints': return LucideIcons.footprints;
      case 'clock': return LucideIcons.clock; // Added for Transfer
      case 'parking': return LucideIcons.circle;
      default: return LucideIcons.circle;
    }
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

    // Calculate padding to account for bottom sheet (35% of screen height)
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.35;

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
}

class LegSelectorModal extends StatefulWidget {
  final List<Leg> options;
  final Leg currentLeg;
  final String title;
  final Function(Leg) onSelect;
  final String Function(Leg)? labelBuilder;

  const LegSelectorModal({
    super.key,
    required this.options,
    required this.currentLeg,
    required this.title,
    required this.onSelect,
    this.labelBuilder,
  });

  @override
  State<LegSelectorModal> createState() => _LegSelectorModalState();
}

class _LegSelectorModalState extends State<LegSelectorModal> {
  String _sortOption = 'Best Value';

  List<Leg> _getSortedOptions() {
    List<Leg> displayOptions = List.from(widget.options);

    displayOptions.sort((a, b) {
      if (_sortOption == 'Lowest Cost') {
        return a.cost.compareTo(b.cost);
      } else if (_sortOption == 'Lowest Time') {
        return a.time.compareTo(b.time);
      } else {
         double scoreA = a.cost + (a.time * 0.15);
         double scoreB = b.cost + (b.time * 0.15);
         return scoreA.compareTo(scoreB);
      }
    });

    return displayOptions;
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

  @override
  Widget build(BuildContext context) {
      final sortedOptions = _getSortedOptions();

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
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        Text(
                          widget.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<String>(
                            value: _sortOption,
                            items: const [
                                DropdownMenuItem(value: 'Best Value', child: Text('Best Value')),
                                DropdownMenuItem(value: 'Lowest Cost', child: Text('Lowest Cost')),
                                DropdownMenuItem(value: 'Lowest Time', child: Text('Lowest Time')),
                            ],
                            onChanged: (val) {
                                if (val != null) setState(() => _sortOption = val);
                            },
                            underline: Container(),
                            icon: const Icon(LucideIcons.arrowUpDown, size: 16),
                        ),
                    ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: sortedOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final option = sortedOptions[index];
                    final isSelected = option.id == widget.currentLeg.id;

                    double priceDiff = option.cost - widget.currentLeg.cost;
                    int timeDiff = option.time - widget.currentLeg.time;

                    return GestureDetector(
                      onTap: () => widget.onSelect(option),
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
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_getIconData(option.iconId), size: 24, color: Colors.black87),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.labelBuilder != null ? widget.labelBuilder!(option) : option.label,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    option.detail ?? '',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
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
  }
}
