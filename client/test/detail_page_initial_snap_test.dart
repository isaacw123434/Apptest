import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:client/screens/detail_page.dart';
import 'package:client/models.dart';
import 'package:client/services/api_service.dart';
import 'package:latlong2/latlong.dart';

class MockApiService extends ApiService {
  @override
  Future<InitData> fetchInitData({String? routeId}) async {
    return InitData(
      journeys: [],
      segmentOptions: SegmentOptions(
        firstMile: [],
        mainLeg: Leg(
          id: 'main',
          label: 'Main Leg',
          time: 10,
          cost: 5.0,
          distance: 10.0,
          riskScore: 0,
          iconId: 'train',
          lineColor: '#000000',
          segments: [],
        ),
        lastMile: [],
      ),
      directDrive: DirectDrive(time: 100, cost: 50, distance: 100),
      mockPath: [],
    );
  }
}

void main() {
  testWidgets('DetailPage DraggableScrollableSheet has correct initialChildSize', (WidgetTester tester) async {
    final mockApiService = MockApiService();

    final dummyResult = JourneyResult(
      id: 'dummy',
      leg1: Leg(
          id: 'first',
          label: 'First',
          time: 10,
          cost: 5,
          distance: 1,
          riskScore: 0,
          iconId: 'car',
          lineColor: '#000000',
          segments: [],
      ),
      leg3: Leg(
          id: 'last',
          label: 'Last',
          time: 5,
          cost: 2,
          distance: 1,
          riskScore: 0,
          iconId: 'bus',
          lineColor: '#000000',
          segments: [],
      ),
      cost: 10,
      time: 25,
      buffer: 0,
      risk: 0,
      emissions: Emissions(val: 0, percent: 0),
    );

    await tester.pumpWidget(MaterialApp(
      home: DetailPage(
        journeyResult: dummyResult,
        apiService: mockApiService,
      ),
    ));

    await tester.pumpAndSettle();

    // Flush the timer in onMapReady
    await tester.pump(const Duration(seconds: 1));

    final sheetFinder = find.byType(DraggableScrollableSheet);
    expect(sheetFinder, findsOneWidget);

    final DraggableScrollableSheet sheet = tester.widget(sheetFinder);

    // CURRENT BEHAVIOR: 0.35
    // EXPECTED BEHAVIOR after fix: 0.25

    // Assert current value (it should be 0.35)
    expect(sheet.initialChildSize, 0.25);
  });
}
