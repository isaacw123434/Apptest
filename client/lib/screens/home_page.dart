import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'summary_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _fromController = TextEditingController(
    text: 'St Chads, Leeds',
  );
  final TextEditingController _toController = TextEditingController(
    text: 'East Leake, Loughborough',
  );
  final TextEditingController _timeController = TextEditingController(
    text: '09:00',
  );
  final String _timeType = 'Depart';
  String? _currentRouteId;

  bool _isModeDropdownOpen = false;
  final Map<String, bool> _selectedModes = {
    'train': true,
    'bus': true,
    'car': true,
    'taxi': true,
    'bike': false,
  };

  final List<Map<String, dynamic>> _modeOptions = [
    {'id': 'train', 'icon': LucideIcons.train, 'label': 'Train'},
    {'id': 'bus', 'icon': LucideIcons.bus, 'label': 'Bus'},
    {'id': 'car', 'icon': LucideIcons.car, 'label': 'Car'},
    {'id': 'taxi', 'icon': LucideIcons.car, 'label': 'Taxi'},
    {'id': 'bike', 'icon': LucideIcons.bike, 'label': 'Bike'},
  ];

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
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              _buildSearchForm(),
              _buildSavedRoutes(),
              _buildUpcomingJourneys(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF4F46E5), // Brand Color
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'EndMile',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF3730A3), // Brand Dark
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInputRow(LucideIcons.circle, _fromController, Colors.grey),
          const SizedBox(height: 12),
          _buildInputRow(LucideIcons.circle, _toController, Colors.black),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Slate 100
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      DropdownButton<String>(
                        value: _timeType,
                        underline: Container(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B), // Slate 500
                        ),
                        icon: const Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: Color(0xFF94A3B8),
                        ),
                        onChanged: null,
                        items: <String>['Depart', 'Arrive']
                            .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            })
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _timeController,
                          readOnly: true,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A), // Slate 900
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fromController.text = 'St Chads, Leeds';
                      _toController.text = 'East Leake, Loughborough';
                      _currentRouteId = 'route1';
                    });
                    _handleSearch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5), // Brand
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Mock Route 1',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _fromController.text = 'Hurn View Beverley';
                      _toController.text = 'Wellington Place Leeds';
                      _currentRouteId = 'route2';
                    });
                    _handleSearch();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E), // Teal
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Mock Route 2',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () {
              setState(() {
                _isModeDropdownOpen = !_isModeDropdownOpen;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter Modes',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B), // Slate 500
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 16,
                    color: const Color(0xFF64748B), // Slate 500
                  ),
                ],
              ),
            ),
          ),
          if (_isModeDropdownOpen) ...[
            const SizedBox(height: 8),
            Row(
              children: _modeOptions.asMap().entries.map((entry) {
                final index = entry.key;
                final mode = entry.value;
                final isSelected = _selectedModes[mode['id']]!;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: index == _modeOptions.length - 1 ? 0 : 8.0,
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedModes[mode['id']] = !isSelected;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.white, // Blue 50
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF4F46E5)
                                : const Color(
                                    0xFFE2E8F0,
                                  ), // Accent or Slate 200
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              mode['icon'],
                              size: 20,
                              color: isSelected
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              mode['label'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputRow(
    IconData icon,
    TextEditingController controller,
    Color dotColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Slate 100
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: true,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF334155), // Slate 700
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedRoutes() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saved Routes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF1E293B), // Slate 800
                ),
              ),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4F46E5), // Brand
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...['Home → Work', 'Leeds → Manchester'].map(
            (route) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF1F5F9)), // Slate 100
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFE0E7FF,
                      ), // Brand Light (Blue 100ish)
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.heart,
                      size: 18,
                      color: Color(0xFF4F46E5),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    route,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF334155), // Slate 700
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

  Widget _buildUpcomingJourneys() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Journeys',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF1E293B), // Slate 800
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF1F5F9)), // Slate 100
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4F46E5), // Brand
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        LucideIcons.train,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Leeds → York',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B), // Slate 800
                          ),
                        ),
                        Text(
                          'Tomorrow, 08:30',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B), // Slate 500
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9), // Slate 100
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.75,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5), // Brand
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'On time',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ), // Slate 400
                    ),
                    Text(
                      'Platform 4',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ), // Slate 400
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
