import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:client/services/api_service.dart';
import 'package:client/models.dart';
import 'dart:convert';

class MockClient extends http.BaseClient {
  final Future<http.Response> Function(http.Request request) _handler;

  MockClient(this._handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request is! http.Request) {
         throw UnimplementedError('Only http.Request supported');
    }
    final response = await _handler(request);
    final bytes = utf8.encode(response.body);
    return http.StreamedResponse(
        Stream.value(bytes), response.statusCode,
        headers: response.headers,
        request: request,
        contentLength: bytes.length,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ApiService', () {
    test('fetchInitData returns InitData with paths (Asset Fallback)', () async {
      // Mock API failure to force fallback to assets
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final apiService = ApiService(client: mockClient);

      final initData = await apiService.fetchInitData();

      // Check First Mile (Bus) - verifying asset data structure
      final firstMile = initData.segmentOptions.firstMile;
      final busLeg = firstMile.firstWhere((leg) => leg.id == 'bus');
      final busSegment = busLeg.segments.first;

      expect(busSegment.path, isNotNull);
      expect(busSegment.path!.isNotEmpty, isTrue);

      // Check Main Leg (Train)
      final mainLeg = initData.segmentOptions.mainLeg;
      final mainSegment = mainLeg.segments.first;

      expect(mainSegment.path, isNotNull);
      expect(mainSegment.path!.isNotEmpty, isTrue);
    });

    test('searchJourneys smart tab sorting', () async {
      // Mock API failure to force fallback to assets
      final mockClient = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final apiService = ApiService(client: mockClient);

      final selectedModes = {
        'train': true,
        'bus': true,
        'car': true,
        'taxi': true,
        'bike': true,
      };

      final results = await apiService.searchJourneys(
        tab: 'smart',
        selectedModes: selectedModes,
      );

      // Check if sorted by updated logic
      // Note: minRisk cancels out when comparing two scores from the same search,
      // so we can verify order using raw risk * 20.0
      for (int i = 0; i < results.length - 1; i++) {
          double scoreA = results[i].cost + (results[i].time * 0.3) + (results[i].risk * 20.0);
          double scoreB = results[i+1].cost + (results[i+1].time * 0.3) + (results[i+1].risk * 20.0);
          expect(scoreA <= scoreB, isTrue, reason: 'Results should be sorted by score (Cost + 0.3*Time + 20*Risk)');
      }
    });

    test('fetchInitData returns data from API on success', () async {
      final mockClient = MockClient((request) async {
        if (request.url.toString() == 'https://endmilerouting.co.uk/assets/assets/routes.json') {
          return http.Response('''
            {
              "groups": [],
              "mockPath": [],
              "directDrive": {"time": 0, "cost": 0, "distance": 0, "co2": 0}
            }
          ''', 200);
        }
        return http.Response('Not Found', 404);
      });

      final apiService = ApiService(client: mockClient);
      final data = await apiService.fetchInitData();

      expect(data, isA<InitData>());
      // Our mocked API returns empty groups, so firstMile should be empty
      expect(data.segmentOptions.firstMile, isEmpty);
    });

    test('fetchInitData falls back to assets on API failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response('Error', 500);
      });

      final apiService = ApiService(client: mockClient);

      final data = await apiService.fetchInitData();

      expect(data, isA<InitData>());
      // Real assets/routes.json has data, so firstMile should be empty
      expect(data.segmentOptions.firstMile, isNotEmpty);
    });
  });
}
