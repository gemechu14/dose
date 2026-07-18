import 'package:flutter/material.dart';

/// Material 3–style breakpoints for adaptive layouts.
enum ScreenSize {
  compact,
  medium,
  expanded,
  large,
}

abstract final class Responsive {
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 840;
  static const double desktopBreakpoint = 1200;

  static const double authFormMaxWidth = 420;
  static const double contentMaxWidthMedium = 720;
  static const double contentMaxWidthExpanded = 960;
  static const double contentMaxWidthLarge = 1200;

  static ScreenSize screenSizeOf(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return ScreenSize.large;
    if (width >= tabletBreakpoint) return ScreenSize.expanded;
    if (width >= mobileBreakpoint) return ScreenSize.medium;
    return ScreenSize.compact;
  }

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.compact;

  static bool isMediumOrWider(BuildContext context) =>
      widthOf(context) >= mobileBreakpoint;

  static bool isExpandedOrWider(BuildContext context) =>
      widthOf(context) >= tabletBreakpoint;

  static bool isLarge(BuildContext context) =>
      screenSizeOf(context) == ScreenSize.large;

  /// Use side navigation instead of bottom navigation.
  static bool useSideNavigation(BuildContext context) =>
      isExpandedOrWider(context);

  static double contentMaxWidth(BuildContext context) {
    switch (screenSizeOf(context)) {
      case ScreenSize.compact:
        return double.infinity;
      case ScreenSize.medium:
        return contentMaxWidthMedium;
      case ScreenSize.expanded:
        return contentMaxWidthExpanded;
      case ScreenSize.large:
        return contentMaxWidthLarge;
    }
  }

  static EdgeInsets pagePadding(BuildContext context) {
    switch (screenSizeOf(context)) {
      case ScreenSize.compact:
        return const EdgeInsets.symmetric(horizontal: 16);
      case ScreenSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24);
      case ScreenSize.expanded:
      case ScreenSize.large:
        return const EdgeInsets.symmetric(horizontal: 32);
    }
  }

  static int gridColumns(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
    int large = 5,
  }) {
    switch (screenSizeOf(context)) {
      case ScreenSize.compact:
        return compact;
      case ScreenSize.medium:
        return medium;
      case ScreenSize.expanded:
        return expanded;
      case ScreenSize.large:
        return large;
    }
  }

  static SliverGridDelegate adaptiveGridDelegate(
    BuildContext context, {
    int compact = 2,
    int medium = 3,
    int expanded = 4,
    int large = 5,
    double crossAxisSpacing = 12,
    double mainAxisSpacing = 12,
    double childAspectRatio = 1.4,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: gridColumns(
        context,
        compact: compact,
        medium: medium,
        expanded: expanded,
        large: large,
      ),
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
