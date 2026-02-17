import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/emission_utils.dart';
import '../utils/time_utils.dart';

class DirectDrivePage extends StatefulWidget {
  final ApiService? apiService;
  final String? routeId;

  const DirectDrivePage({super.key, this.apiService, this.routeId});

  @override
  State<DirectDrivePage> createState() => _DirectDrivePageState();
}

class _DirectDrivePageState extends State<DirectDrivePage> {
  late final ApiService _apiService;
  InitData? _initData;
  MapController? _mapController;
  List<LatLng> _routePoints = [];
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _apiService = widget.apiService ?? ApiService();
    _mapController = MapController();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchInitData(routeId: widget.routeId);
      if (mounted) {
        List<Marker> markers = [];
        if (data.mockPath.isNotEmpty) {
           markers.add(Marker(
             point: data.mockPath.first,
             width: 24,
             height: 24,
             child: _buildMarkerWidget(isStart: true),
           ));
           markers.add(Marker(
             point: data.mockPath.last,
             width: 24,
             height: 24,
             child: _buildMarkerWidget(isEnd: true),
           ));
        }

        setState(() {
          _initData = data;
          _routePoints = data.mockPath;
          _markers = markers;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
           _zoomToFit();
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.example.app',
              ),
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    )
                  ],
                ),
              if (_markers.isNotEmpty)
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

          // 2. Info Card
          if (_initData != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -5))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Direct Drive',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const Text(
                                'St Chads → East Leake',
                                style: TextStyle(color: Colors.grey),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Slate 100
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.car, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _buildInfoBox('Cost', '£${_initData!.directDrive.cost.toStringAsFixed(2)}')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInfoBox('Time', formatDuration(_initData!.directDrive.time))),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInfoBox('Distance', '${_initData!.directDrive.distance} mi')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildInfoBox('CO₂', '${(_initData!.directDrive.co2 ?? calculateEmission(_initData!.directDrive.distance, IconIds.car)).toStringAsFixed(2)} kg')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(LucideIcons.map),
                        label: const Text('Open Maps'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB), // Blue 600
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
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
      return const SizedBox();
    }
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC), // Slate 50
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Color(0xFF64748B), // Slate 500
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A), // Slate 900
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomToFit() {
    if (!mounted) return;
    if (_mapController == null || _routePoints.isEmpty) return;

    double minLat = _routePoints.first.latitude;
    double maxLat = _routePoints.first.latitude;
    double minLng = _routePoints.first.longitude;
    double maxLng = _routePoints.first.longitude;

    for (var point in _routePoints) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Calculate padding to account for bottom sheet (approx 35% of screen height)
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
