import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/home_page.dart';
import 'screens/direct_drive_page.dart';
import 'utils/google_maps_config_stub.dart' if (dart.library.html) 'utils/google_maps_config_web.dart';

void main() {
  setupGoogleMaps();
  runApp(const JourneyPlannerApp());
}

class JourneyPlannerApp extends StatelessWidget {
  const JourneyPlannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journey Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4F46E5), // Indigo
          primary: const Color(0xFF4F46E5),
          secondary: const Color(0xFF0F766E), // Teal
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Slate 50
      ),
      home: const HomePage(),
      routes: {
        '/direct-drive': (context) => const DirectDrivePage(),
      },
    );
  }
}
