import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

IconData? getIconData(String iconId) {
  switch (iconId) {
    case 'train':
      return LucideIcons.train;
    case 'bus':
      return LucideIcons.bus;
    case 'car':
      return LucideIcons.car;
    case 'bike':
      return LucideIcons.bike;
    case 'footprints':
      return LucideIcons.footprints;
    case 'clock':
      return LucideIcons.clock;
    case 'parking':
      return LucideIcons.circle;
    default:
      return null;
  }
}
