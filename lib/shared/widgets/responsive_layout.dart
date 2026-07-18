import 'package:flutter/material.dart';

import '../../core/utils/responsive.dart';

/// Caps content width without adding padding.
class ResponsiveConstraint extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final AlignmentGeometry alignment;

  const ResponsiveConstraint({
    super.key,
    required this.child,
    this.maxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedMaxWidth = maxWidth ?? Responsive.contentMaxWidth(context);

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
              resolvedMaxWidth.isFinite ? resolvedMaxWidth : double.infinity,
        ),
        child: child,
      ),
    );
  }
}

/// Centers page content and caps its width on tablet/desktop.
class ResponsivePage extends StatelessWidget {
  final Widget child;
  final bool centerVertically;
  final double? maxWidth;
  final EdgeInsetsGeometry? padding;
  final bool applyPadding;

  const ResponsivePage({
    super.key,
    required this.child,
    this.centerVertically = false,
    this.maxWidth,
    this.padding,
    this.applyPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        applyPadding ? (padding ?? Responsive.pagePadding(context)) : null;

    Widget content = child;
    if (resolvedPadding != null && resolvedPadding != EdgeInsets.zero) {
      content = Padding(padding: resolvedPadding, child: content);
    }

    return ResponsiveConstraint(
      maxWidth: maxWidth,
      alignment:
          centerVertically ? Alignment.center : Alignment.topCenter,
      child: content,
    );
  }
}

/// Narrow, centered layout for auth and form-only screens.
class ResponsiveAuthPage extends StatelessWidget {
  final Widget child;

  const ResponsiveAuthPage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ResponsivePage(
      maxWidth: Responsive.authFormMaxWidth,
      centerVertically: Responsive.isExpandedOrWider(context),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.isCompact(context) ? 24 : 32,
        vertical: Responsive.isExpandedOrWider(context) ? 32 : 32,
      ),
      child: child,
    );
  }
}

/// Builds different layouts based on the current screen size bucket.
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size) builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return builder(context, Responsive.screenSizeOf(context));
  }
}
