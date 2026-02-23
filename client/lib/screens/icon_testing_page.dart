import 'package:flutter/material.dart';
import '../models.dart';
import '../services/api_service.dart';
import '../widgets/journey_result_card.dart';
import '../widgets/timeline_summary_view.dart';

class IconTestingPage extends StatefulWidget {
  const IconTestingPage({super.key});

  @override
  State<IconTestingPage> createState() => _IconTestingPageState();
}

class _IconTestingPageState extends State<IconTestingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<JourneyResult> _mock1Routes = [];
  List<JourneyResult> _mock2Routes = [];
  Leg? _mainLeg1;
  Leg? _mainLeg2;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final modes = {'train': true, 'bus': true, 'walk': true, 'taxi': true, 'car': true};

      // Mock 1
      final initData1 = await _apiService.fetchInitData(routeId: 'route1');
      final results1 = await _apiService.searchJourneys(
        tab: 'smart',
        selectedModes: modes,
        routeId: 'route1',
      );

      // Mock 2
      final initData2 = await _apiService.fetchInitData(routeId: 'route2');
      final results2 = await _apiService.searchJourneys(
        tab: 'smart',
        selectedModes: modes,
        routeId: 'route2',
      );

      if (mounted) {
        setState(() {
          _mainLeg1 = initData1.segmentOptions.mainLeg;
          _mock1Routes = results1;

          _mainLeg2 = initData2.segmentOptions.mainLeg;
          _mock2Routes = results2;

          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Icon Testing'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mock 1'),
            Tab(text: 'Mock 2'),
          ],
        ),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildRouteList(_mock1Routes, _mainLeg1, 'route1'),
              _buildRouteList(_mock2Routes, _mainLeg2, 'route2'),
            ],
          ),
    );
  }

  Widget _buildRouteList(List<JourneyResult> routes, Leg? mainLeg, String routeId) {
     final trainRoutes = routes.where((r) {
        bool hasTrain = false;
        if (mainLeg != null && mainLeg.segments.any((s) => s.mode.toLowerCase() == 'train')) hasTrain = true;
        if (r.leg1.segments.any((s) => s.mode.toLowerCase() == 'train')) hasTrain = true;
        if (r.leg3.segments.any((s) => s.mode.toLowerCase() == 'train')) hasTrain = true;
        return hasTrain;
     }).toList();

     return ListView.separated(
       padding: const EdgeInsets.all(16),
       itemCount: trainRoutes.length,
       separatorBuilder: (context, index) => const Divider(height: 32, thickness: 2),
       itemBuilder: (context, index) {
         final route = trainRoutes[index];
         return Column(
           crossAxisAlignment: CrossAxisAlignment.stretch,
           children: [
             Text('Route Option ${index + 1}', style: Theme.of(context).textTheme.titleMedium),
             const SizedBox(height: 8),
             _buildVariant(route, mainLeg, routeId, TimelineLayoutType.original, 'Current Layout'),
             const SizedBox(height: 16),
             _buildVariant(route, mainLeg, routeId, TimelineLayoutType.textPreferred, 'Variant 1: Text Preference'),
             const SizedBox(height: 16),
             _buildVariant(route, mainLeg, routeId, TimelineLayoutType.logoAsIcon, 'Variant 2: Logo as Icon'),
           ],
         );
       },
     );
  }

  Widget _buildVariant(JourneyResult result, Leg? mainLeg, String routeId, TimelineLayoutType type, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 4),
        JourneyResultCard(
          result: result,
          isTopChoice: false,
          isLeastRisky: false,
          routeId: routeId,
          mainLeg: mainLeg,
          selectedModes: const {'train': true, 'bus': true, 'walk': true},
          layoutType: type,
          forceLogos: false,
        ),
      ],
    );
  }
}
