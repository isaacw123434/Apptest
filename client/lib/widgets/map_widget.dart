import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models.dart';

class MapWidget extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final double initialZoom;
  final JourneyResult? routeData;

  const MapWidget({
    super.key,
    this.initialLat = 54.5,
    this.initialLng = -3.0,
    this.initialZoom = 6.0,
    this.routeData,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  late final MapController _mapController;
  List<Polyline> _polylines = [];
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _updateRoute();
  }

  @override
  void didUpdateWidget(covariant MapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.routeData != oldWidget.routeData) {
      _updateRoute();
    }
  }

  void _updateRoute() {
    if (widget.routeData == null) {
      setState(() {
        _polylines = [];
      });
      return;
    }

    final result = widget.routeData!;
    List<Polyline> lines = [];

    List<Segment> allSegments = [];
    allSegments.addAll(result.leg1.segments);
    allSegments.addAll(result.leg3.segments);

    void addPolyline(Segment seg) {
      if (seg.subSegments != null && seg.subSegments!.isNotEmpty) {
        for (var sub in seg.subSegments!) {
          addPolyline(sub);
        }
        return;
      }

      if (seg.path != null && seg.path!.isNotEmpty) {
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

    setState(() {
      _polylines = lines;
    });

    if (_isMapReady) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _zoomToFit();
      });
    }
  }

  Color _parseColor(String lineColor) {
    try {
      return Color(int.parse(lineColor.replaceAll('#', ''), radix: 16) + 0xFF000000);
    } catch (e) {
      return const Color(0xFF4F46E5);
    }
  }

  void _zoomToFit() {
    if (!mounted || _polylines.isEmpty) return;

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

    _mapController.fitCamera(CameraFit.bounds(
      bounds: bounds,
      padding: const EdgeInsets.all(50),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(widget.initialLat, widget.initialLng),
        initialZoom: widget.initialZoom,
        onMapReady: () {
          _isMapReady = true;
          if (_polylines.isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 200), () {
              if (mounted) _zoomToFit();
            });
          }
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
      ],
    );
  }
}
