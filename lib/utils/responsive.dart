import 'package:flutter/material.dart';

/// Centralized responsive helpers for M@LI-NTIC app.
class Responsive {
  final BuildContext context;
  late final double _width;
  late final double _height;

  Responsive(this.context) {
    final size = MediaQuery.of(context).size;
    _width = size.width;
    _height = size.height;
  }

  bool get isMobile => _width < 600;
  bool get isSmallTablet => _width >= 600 && _width < 768;
  bool get isTablet => _width >= 768 && _width < 1100;
  bool get isDesktop => _width >= 1100;
  bool get isMobileOrSmall => _width < 768;

  double get screenWidth => _width;
  double get screenHeight => _height;

  EdgeInsets get contentPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
  }

  EdgeInsets get horizontalPadding {
    if (isMobile) return const EdgeInsets.symmetric(horizontal: 12);
    if (isTablet) return const EdgeInsets.symmetric(horizontal: 16);
    return const EdgeInsets.symmetric(horizontal: 24);
  }

  int get gridColumns {
    if (isMobile) return 1;
    if (isSmallTablet || isTablet) return 2;
    return 3;
  }

  int get statColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  double get statAspectRatio {
    if (isMobile) return 1.35;
    if (isTablet) return 1.6;
    return 1.8;
  }

  int get actionColumns => isMobile ? 2 : 4;
  int get summaryColumns {
    if (isMobile) return 1;
    if (isTablet) return 2;
    return 3;
  }

  double get dialogMaxWidth {
    if (isMobile) return _width - 24;
    if (isTablet) return 540;
    return 600;
  }

  double get dialogMaxHeight => isMobile ? _height * 0.88 : _height * 0.82;

  double get headingFontSize {
    if (isMobile) return 16;
    if (isTablet) return 19;
    return 22;
  }

  double get subheadingFontSize {
    if (isMobile) return 13;
    if (isTablet) return 14;
    return 15;
  }

  double get bodyFontSize => isMobile ? 12 : 13;
  double get captionFontSize => isMobile ? 11 : 12;

  double get cardBorderRadius => isMobile ? 14 : 18;
  double get sectionSpacing => isMobile ? 12 : 20;
  double get cardSpacing => isMobile ? 8 : 12;

  double get chartHeight {
    if (isMobile) return 130;
    if (isTablet) return 150;
    return 170;
  }

  double get miniChartSize => isMobile ? 80 : 100;
  double get iconSize => isMobile ? 18 : 20;
  double get largeIconSize => isMobile ? 24 : 28;

  bool get showDataTable => !isMobileOrSmall;
  double get maxContentWidth => 1280;
  double get formMaxWidth => isMobile ? _width - 32 : 420;

  T responsive<T>({required T mobile, T? tablet, required T desktop}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet ?? desktop;
    return desktop;
  }
}

extension ResponsiveContext on BuildContext {
  Responsive get r => Responsive(this);
  bool get isMobileScreen => MediaQuery.of(this).size.width < 600;
  bool get isTabletScreen =>
      MediaQuery.of(this).size.width >= 768 &&
      MediaQuery.of(this).size.width < 1100;
  bool get isDesktopScreen => MediaQuery.of(this).size.width >= 1100;
}
