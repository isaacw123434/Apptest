import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models.dart';

class ApiService {
  final String baseUrl = 'http://localhost:3000/api';

  Future<InitData> fetchInitData() async {
    final response = await http.get(Uri.parse('$baseUrl/init'));

    if (response.statusCode == 200) {
      return InitData.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load init data');
    }
  }

  Future<List<JourneyResult>> searchJourneys({
    required String tab,
    required Map<String, bool> selectedModes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/search'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, dynamic>{
        'tab': tab,
        'selectedModes': selectedModes,
      }),
    );

    if (response.statusCode == 200) {
      Iterable l = jsonDecode(response.body);
      return List<JourneyResult>.from(
          l.map((model) => JourneyResult.fromJson(model)));
    } else {
      throw Exception('Failed to search journeys');
    }
  }
}
