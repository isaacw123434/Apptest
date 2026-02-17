import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/search_form.dart';
import '../widgets/home/mock_route_buttons.dart';
import '../widgets/home/saved_routes_section.dart';
import '../widgets/home/upcoming_journeys_section.dart';
import 'summary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController(text: 'St Chads, Leeds');
  final TextEditingController _toController = TextEditingController(text: 'East Leake, Loughborough');
  final TextEditingController _timeController = TextEditingController(text: '09:00');
  String _timeType = 'Depart';
  String? _currentRouteId;

  Map<String, bool> _selectedModes = {
    'train': true,
    'bus': true,
    'car': true,
    'taxi': true,
    'bike': false,
  };

  void _handleSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SummaryPage(
          from: _fromController.text,
          to: _toController.text,
          timeType: _timeType,
          time: _timeController.text,
          selectedModes: _selectedModes,
          routeId: _currentRouteId,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Header(),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    SearchForm(
                      fromController: _fromController,
                      toController: _toController,
                      timeController: _timeController,
                      timeType: _timeType,
                      onTimeTypeChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _timeType = value;
                          });
                        }
                      },
                      selectedModes: _selectedModes,
                      onModeChanged: (modeId, isSelected) {
                        setState(() {
                          final newModes = Map<String, bool>.from(_selectedModes);
                          newModes[modeId] = isSelected;
                          _selectedModes = newModes;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    MockRouteButtons(
                      onMockRoute1: () {
                        setState(() {
                          _fromController.text = 'St Chads, Leeds';
                          _toController.text = 'East Leake, Loughborough';
                          _currentRouteId = 'route1';
                        });
                        _handleSearch();
                      },
                      onMockRoute2: () {
                        setState(() {
                          _fromController.text = 'Hurn View Beverley';
                          _toController.text = 'Wellington Place Leeds';
                          _currentRouteId = 'route2';
                        });
                        _handleSearch();
                      },
                    ),
                  ],
                ),
              ),
              const SavedRoutesSection(),
              const UpcomingJourneysSection(),
            ],
          ),
        ),
      ),
    );
  }
}
