// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void setupGoogleMaps() {
  const apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  if (apiKey.isEmpty) {
    // print('WARNING: GOOGLE_MAPS_API_KEY is not set.');
    return;
  }

  if (html.document.getElementById('google-maps-script') != null) {
    return;
  }

  final script = html.ScriptElement()
    ..src = 'https://maps.googleapis.com/maps/api/js?key=$apiKey'
    ..id = 'google-maps-script'
    ..async = true
    ..defer = true;

  html.document.head!.append(script);
}
