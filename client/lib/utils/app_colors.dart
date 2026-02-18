import 'package:flutter/material.dart';

class AppColors {
  static Color _hsl(double h, double s, double l) =>
      HSLColor.fromAHSL(1.0, h, s, l).toColor();

  static final Color brand = _hsl(243.4, 0.754, 0.586); // #4F46E5
  static final Color brandDark = _hsl(243.7, 0.545, 0.414); // #3730A3
  static final Color brandLight = _hsl(226.5, 1.000, 0.939); // #E0E7FF
  static final Color secondary = _hsl(175.3, 0.774, 0.261); // #0F766E
  static final Color slate50 = _hsl(210.0, 0.400, 0.980); // #F8FAFC
  static final Color slate100 = _hsl(210.0, 0.400, 0.961); // #F1F5F9
  static final Color slate200 = _hsl(214.3, 0.318, 0.914); // #E2E8F0
  static final Color slate400 = _hsl(215.0, 0.202, 0.651); // #94A3B8
  static final Color slate500 = _hsl(215.4, 0.163, 0.469); // #64748B
  static final Color slate700 = _hsl(215.3, 0.250, 0.267); // #334155
  static final Color slate800 = _hsl(217.2, 0.326, 0.175); // #1E293B
  static final Color slate900 = _hsl(222.2, 0.474, 0.112); // #0F172A
  static final Color blue50 = _hsl(213.8, 1.000, 0.969); // #EFF6FF

  // Derived colors
  static final Color brandHover = _hsl(243.4, 0.754, 0.486); // 10% darker than brand
}
