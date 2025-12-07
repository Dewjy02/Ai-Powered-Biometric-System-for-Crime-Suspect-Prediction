import 'package:flutter/material.dart';

class Responsive {
  // method to check whether the device is a mobile(mobile screen size)
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 850;

  // method to check whether the device is a tablet(tablet screen size)
  static bool isTablet(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return width >= 850 && width < 1100;
  }

  // method to check whether the device is a tablet(tablet screen size)
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= 1100;
}