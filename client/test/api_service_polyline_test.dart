import 'package:flutter_test/flutter_test.dart';
import 'package:client/services/api_service.dart';
import 'package:client/models.dart';

void main() {
  test('fetchInitData populates segments with correct paths and colors from new data', () async {
    final apiService = ApiService();
    final initData = await apiService.fetchInitData();

    final options = initData.segmentOptions;

    // --- First Mile Checks ---

    // 1. Cycle (Personal Bike)
    // Expecting color #008000 (Green) from "Cycle to Station..."
    final cycleLeg = options.firstMile.firstWhere((leg) => leg.id == 'cycle');
    expect(cycleLeg.segments.length, 1);
    expect(cycleLeg.segments.first.lineColor, '#008000');
    expect(cycleLeg.segments.first.path, isNotNull);
    expect(cycleLeg.segments.first.path!.isNotEmpty, true);

    // 2. Bus (Bus Line 24)
    // Expecting color #008080 from "Bus to Station..."
    final busLeg = options.firstMile.firstWhere((leg) => leg.id == 'bus');
    expect(busLeg.segments.length, 1);
    expect(busLeg.segments.first.lineColor, '#008080');
    expect(busLeg.segments.first.path, isNotNull);
    expect(busLeg.segments.first.path!.isNotEmpty, true);

    // 3. Drive & Park
    // Expecting color #000000 from "Drive to Station..."
    final driveLeg = options.firstMile.firstWhere((leg) => leg.id == 'drive_park');
    expect(driveLeg.segments.length, 1);
    expect(driveLeg.segments.first.lineColor, '#000000');
    expect(driveLeg.segments.first.path, isNotNull);
    expect(driveLeg.segments.first.path!.isNotEmpty, true);

    // 4. Train via Headingley (Walk)
    // Expecting Walk (#ADD8E6) + Train (#0000FF) from "Walk/Train + Train + Cycle"
    final trainWalkLeg = options.firstMile.firstWhere((leg) => leg.id == 'train_walk_headingley');
    expect(trainWalkLeg.segments.length, 2);
    expect(trainWalkLeg.segments[0].mode, 'walk');
    expect(trainWalkLeg.segments[0].lineColor, '#ADD8E6');
    expect(trainWalkLeg.segments[0].path, isNotNull);

    expect(trainWalkLeg.segments[1].mode, 'train');
    expect(trainWalkLeg.segments[1].lineColor, '#0000FF');
    expect(trainWalkLeg.segments[1].path, isNotNull);

    // --- Main Leg Checks ---

    // 5. Main Train
    // Expecting #660000 from any route leg 1
    final mainLeg = options.mainLeg;
    expect(mainLeg.segments.length, 1);
    expect(mainLeg.segments.first.lineColor, '#660000');
    expect(mainLeg.segments.first.path, isNotNull);
    expect(mainLeg.segments.first.path!.isNotEmpty, true);

    // --- Last Mile Checks ---

    // 6. Last Mile Bus (Bus Line 1)
    // Expecting #008080 from "Cycle to Station + Train + Bus" leg 2
    final lastBusLeg = options.lastMile.firstWhere((leg) => leg.id == 'bus');
    expect(lastBusLeg.segments.length, 1);
    expect(lastBusLeg.segments.first.lineColor, '#008080');
    expect(lastBusLeg.segments.first.path, isNotNull);

    // 7. Last Mile Uber
    // Expecting #000000
    final lastUberLeg = options.lastMile.firstWhere((leg) => leg.id == 'uber');
    expect(lastUberLeg.segments.length, 1);
    expect(lastUberLeg.segments.first.lineColor, '#000000');
    expect(lastUberLeg.segments.first.path, isNotNull);
  });
}
