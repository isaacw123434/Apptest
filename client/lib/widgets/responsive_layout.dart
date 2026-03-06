import 'package:flutter/material.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobileView;
  final Widget desktopLeftPanel;
  final Widget desktopRightPanel;

  const ResponsiveLayout({
    super.key,
    required this.mobileView,
    required this.desktopLeftPanel,
    required this.desktopRightPanel,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // If width is less than 800, assume mobile/tablet portrait
        if (constraints.maxWidth < 800) {
          return mobileView;
        }
        // Otherwise, use desktop split-screen
        else {
          return Row(
            children: [
              // Left Panel (Fixed width, acts like a mobile screen)
              SizedBox(
                width: 400,
                child: desktopLeftPanel,
              ),
              // Vertical Divider
              const VerticalDivider(width: 1, thickness: 1),
              // Right Panel (Map takes up remaining space)
              Expanded(
                child: desktopRightPanel,
              ),
            ],
          );
        }
      },
    );
  }
}
