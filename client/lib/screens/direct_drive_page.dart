import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../utils/emission_utils.dart';
import '../services/mock_data.dart';

class DirectDrivePage extends StatefulWidget {
  const DirectDrivePage({super.key});

  @override
  State<DirectDrivePage> createState() => _DirectDrivePageState();
}

class _DirectDrivePageState extends State<DirectDrivePage> {
  final ApiService _apiService = ApiService();
  InitData? _initData;
  GoogleMapController? _mapController;
  List<latlong.LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _apiService.fetchInitData();
      setState(() {
        _initData = data;
        _routePoints = data.mockPath;
      });
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
          if (_routePoints.isNotEmpty)
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(53.28, -1.37),
                zoom: 9.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              polylines: {
                Polyline(
                  polylineId: const PolylineId('direct_drive'),
                  points: _routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                  color: Colors.blue,
                  width: 4,
                )
              },
              mapType: MapType.normal,
              rotateGesturesEnabled: false,
            )
          else
            const Center(child: CircularProgressIndicator()),

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
                        Expanded(child: _buildInfoBox('Time', '${(_initData!.directDrive.time / 60).floor()}hr ${_initData!.directDrive.time % 60}m')),
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
                Text('Points: ${_routePoints.length}'),
                const Divider(),
                if (_routePoints.isNotEmpty)
                  Text('First: ${_routePoints.first.latitude.toStringAsFixed(4)}, ${_routePoints.first.longitude.toStringAsFixed(4)}'),
                if (_routePoints.isNotEmpty)
                  Text('Last: ${_routePoints.last.latitude.toStringAsFixed(4)}, ${_routePoints.last.longitude.toStringAsFixed(4)}'),
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
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }
}
