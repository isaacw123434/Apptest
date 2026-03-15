import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/app_colors.dart';
import 'screens/home_page.dart';
import 'screens/direct_drive_page.dart';
import 'widgets/responsive_layout.dart';
import 'widgets/map_widget.dart';
import 'package:provider/provider.dart';
import 'providers/route_provider.dart';
import 'providers/saved_routes_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => SavedRoutesProvider()..init()),
      ],
      child: const JourneyPlannerApp(),
    ),
  );
}

class JourneyPlannerApp extends StatelessWidget {
  const JourneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EndMile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.brand,
          primary: AppColors.brand,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: AppColors.slate50,
      ),
    home: const ResponsiveLayout(
      mobileView: HomePage(),
      desktopLeftPanel: HomePage(),
      desktopRightPanel: MapWidget(
        initialLat: 54.5,
        initialLng: -3.0,
        initialZoom: 6.0,
      ),
    ),
      routes: {
        '/direct-drive': (context) => const DirectDrivePage(),
      },
    );
  }
}
