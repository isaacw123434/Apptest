import 'package:latlong2/latlong.dart';

// ignore_for_file: constant_identifier_names
class IconIds {
  static const String train = 'train';
  static const String car = 'car';
  static const String bus = 'bus';
  static const String bike = 'bike';
  static const String footprints = 'footprints';
  static const String parking = 'parking';
}

class Segment {
  final String mode;
  final String label;
  final String lineColor;
  final String iconId;
  final int time;
  final String? from;
  final String? to;
  final String? detail;
  final List<LatLng>? path;
  final double? co2;
  final double? distance;
  final double cost;
  final int? waitTime;
  final List<Segment>? subSegments;

  Segment({
    required this.mode,
    required this.label,
    required this.lineColor,
    required this.iconId,
    required this.time,
    this.from,
    this.to,
    this.detail,
    this.path,
    this.co2,
    this.distance,
    this.cost = 0.0,
    this.waitTime,
    this.subSegments,
  });

  factory Segment.fromJson(Map<String, dynamic> json) {
    var subSegmentsList = json['subSegments'] as List?;
    List<Segment>? subSegments;
    if (subSegmentsList != null) {
      subSegments = subSegmentsList.map((i) => Segment.fromJson(i)).toList();
    }

    var pathList = json['path'] as List?;
    List<LatLng>? path;
    if (pathList != null) {
      try {
        path = [];
        for (var point in pathList) {
          if (point is List && point.length >= 2) {
            path.add(LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble()));
          } else if (point is LatLng) {
            path.add(point);
          }
        }
      } catch (e) {
        path = null;
      }
    }

    return Segment(
      mode: json['mode'] ?? '',
      label: json['label'] ?? '',
      lineColor: json['lineColor'] ?? '#000000',
      iconId: json['iconId'] ?? '',
      time: json['time'] ?? 0,
      from: json['from'],
      to: json['to'],
      detail: json['detail'],
      path: path,
      co2: json['co2'] != null ? (json['co2'] as num).toDouble() : null,
      distance: json['distance'] != null ? (json['distance'] as num).toDouble() : null,
      cost: (json['cost'] ?? 0).toDouble(),
      waitTime: json['waitTime'],
      subSegments: subSegments,
    );
  }
}

class Leg {
  final String id;
  final String label;
  final String? detail;
  final int time;
  final double cost;
  final double distance;
  final int riskScore;
  final String? riskReason;
  final String iconId;
  final String? color;
  final String? bgColor;
  final String lineColor;
  final String? desc;
  final int? waitTime;
  final int? nextBusIn;
  final bool? recommended;
  final int? platform;
  final List<Segment> segments;
  final double? co2;

  Leg({
    required this.id,
    required this.label,
    this.detail,
    required this.time,
    required this.cost,
    required this.distance,
    required this.riskScore,
    this.riskReason,
    required this.iconId,
    this.color,
    this.bgColor,
    required this.lineColor,
    this.desc,
    this.waitTime,
    this.nextBusIn,
    this.recommended,
    this.platform,
    required this.segments,
    this.co2,
  });

  factory Leg.fromJson(Map<String, dynamic> json) {
    var segmentsList = json['segments'] as List?;
    List<Segment> segments = segmentsList != null
        ? segmentsList.map((i) => Segment.fromJson(i)).toList()
        : [];

    return Leg(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      detail: json['detail'],
      time: json['time'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      riskScore: json['riskScore'] ?? 0,
      riskReason: json['riskReason'],
      iconId: json['iconId'] ?? '',
      color: json['color'],
      bgColor: json['bgColor'],
      lineColor: json['lineColor'] ?? '#000000',
      desc: json['desc'],
      waitTime: json['waitTime'],
      nextBusIn: json['nextBusIn'],
      recommended: json['recommended'],
      platform: json['platform'],
      segments: segments,
      co2: json['co2'] != null ? (json['co2'] as num).toDouble() : null,
    );
  }
}

class SegmentOptions {
  final List<Leg> firstMile;
  final Leg mainLeg;
  final List<Leg> lastMile;

  SegmentOptions({
    required this.firstMile,
    required this.mainLeg,
    required this.lastMile,
  });

  factory SegmentOptions.fromJson(Map<String, dynamic> json) {
    return SegmentOptions(
      firstMile: (json['firstMile'] as List)
          .map((i) => Leg.fromJson(i))
          .toList(),
      mainLeg: Leg.fromJson(json['mainLeg']),
      lastMile: (json['lastMile'] as List)
          .map((i) => Leg.fromJson(i))
          .toList(),
    );
  }
}

class DirectDrive {
  final int time;
  final double cost;
  final double distance;
  final double? co2;

  DirectDrive({
    required this.time,
    required this.cost,
    required this.distance,
    this.co2,
  });

  factory DirectDrive.fromJson(Map<String, dynamic> json) {
    return DirectDrive(
      time: json['time'] ?? 0,
      cost: (json['cost'] ?? 0).toDouble(),
      distance: (json['distance'] ?? 0).toDouble(),
      co2: json['co2'] != null ? (json['co2'] as num).toDouble() : null,
    );
  }
}

class Emissions {
  final double val;
  final int percent;
  final String? text;

  Emissions({
    required this.val,
    required this.percent,
    this.text,
  });

  factory Emissions.fromJson(Map<String, dynamic> json) {
    return Emissions(
      val: (json['val'] ?? 0).toDouble(),
      percent: json['percent'] ?? 0,
      text: json['text'],
    );
  }
}

class JourneyResult {
  final String id;
  final Leg leg1;
  final Leg leg3;
  final double cost;
  final int time;
  final int buffer;
  final int risk;
  final Emissions emissions;

  JourneyResult({
    required this.id,
    required this.leg1,
    required this.leg3,
    required this.cost,
    required this.time,
    required this.buffer,
    required this.risk,
    required this.emissions,
  });

  factory JourneyResult.fromJson(Map<String, dynamic> json) {
    return JourneyResult(
      id: json['id'] ?? '',
      leg1: Leg.fromJson(json['leg1']),
      leg3: Leg.fromJson(json['leg3']),
      cost: (json['cost'] ?? 0).toDouble(),
      time: json['time'] ?? 0,
      buffer: json['buffer'] ?? 0,
      risk: json['risk'] ?? 0,
      emissions: Emissions.fromJson(json['emissions']),
    );
  }
}

class InitData {
  final SegmentOptions segmentOptions;
  final DirectDrive directDrive;
  final List<LatLng> mockPath;

  InitData({
    required this.segmentOptions,
    required this.directDrive,
    required this.mockPath,
  });

  factory InitData.fromJson(Map<String, dynamic> json) {
    var pathList = json['mockPath'] as List?;
    List<LatLng> mockPath = [];
    if (pathList != null) {
      try {
        for (var point in pathList) {
          if (point is List && point.length >= 2) {
            mockPath.add(LatLng((point[0] as num).toDouble(), (point[1] as num).toDouble()));
          } else if (point is LatLng) {
            mockPath.add(point);
          }
        }
      } catch (e) {
        mockPath = [];
      }
    }

    return InitData(
      segmentOptions: SegmentOptions.fromJson(json['segmentOptions']),
      directDrive: DirectDrive.fromJson(json['directDrive']),
      mockPath: mockPath,
    );
  }
}
