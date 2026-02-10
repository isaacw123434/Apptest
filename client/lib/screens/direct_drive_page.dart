import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models.dart';
import '../services/api_service.dart';

class DirectDrivePage extends StatefulWidget {
  const DirectDrivePage({super.key});

  @override
  State<DirectDrivePage> createState() => _DirectDrivePageState();
}

class _DirectDrivePageState extends State<DirectDrivePage> {
  final ApiService _apiService = ApiService();
  InitData? _initData;
  List<LatLng> _routePoints = [];

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
        _routePoints = data.mockPath.map((p) => LatLng(p[0], p[1])).toList();
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
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
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
                        Column(
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
                            ),
                          ],
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
                        const SizedBox(width: 12),
                        Expanded(child: _buildInfoBox('Time', '${(_initData!.directDrive.time / 60).floor()}hr ${_initData!.directDrive.time % 60}m')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildInfoBox('Distance', '${_initData!.directDrive.distance} mi')),
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
      padding: const EdgeInsets.all(12),
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
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A), // Slate 900
            ),
          ),
        ],
      ),
    );
  }
}
