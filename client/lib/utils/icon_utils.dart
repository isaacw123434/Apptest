import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

IconData? getIconData(String iconId) {
  switch (iconId) {
    case 'train':
      return Icons.train;
    case 'bus':
      return Icons.directions_bus;
    case 'car':
      return Icons.directions_car;
    case 'bike':
      return Icons.pedal_bike;
    case 'footprints':
      return LucideIcons.footprints;
    case 'clock':
      return Icons.access_time;
    case 'parking':
      return Icons.circle;
    default:
      return null;
  }
}
