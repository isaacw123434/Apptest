// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:js' as js;

void setupGoogleMaps() {
  String apiKey = const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // Check URL query parameters
  if (apiKey.isEmpty) {
    final uri = Uri.tryParse(html.window.location.href);
    if (uri != null && uri.queryParameters.containsKey('apiKey')) {
      apiKey = uri.queryParameters['apiKey']!;
    }
  }

  // Check localStorage
  if (apiKey.isEmpty) {
    if (html.window.localStorage.containsKey('GOOGLE_MAPS_API_KEY')) {
      apiKey = html.window.localStorage['GOOGLE_MAPS_API_KEY']!;
    }
  }

  // Check global variable
  if (apiKey.isEmpty) {
    if (js.context.hasProperty('GOOGLE_MAPS_API_KEY')) {
      apiKey = js.context['GOOGLE_MAPS_API_KEY'];
    }
  }

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
