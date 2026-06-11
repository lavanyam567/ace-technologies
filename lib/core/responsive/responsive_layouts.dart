import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import './responsive_config.dart';

/// Responsive Scaffold that adapts to different screen sizes
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final FloatingActionButton? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final BottomNavigationBar? bottomNavigationBar;
  final Color? backgroundColor;
  final bool extendBody;
  final bool resizeToAvoidBottomInset;

  const ResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.backgroundColor,
    this.extendBody = false,
    this.resizeToAvoidBottomInset = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: context.isWebLayout ? null : floatingActionButton,
      drawer: drawer,
      endDrawer: endDrawer,
      bottomNavigationBar: context.isWebLayout ? null : bottomNavigationBar,
      backgroundColor: backgroundColor ?? AppTheme.backgroundColor,
      extendBody: extendBody,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    );
  }
}

/// Web Layout Wrapper that handles responsive design
class WebLayoutWrapper extends StatelessWidget {
  final Widget child;
  final bool centerContent;
  final double maxWidth;

  const WebLayoutWrapper({
    super.key,
    required this.child,
    this.centerContent = true,
    this.maxWidth = 1400,
  });

  @override
  Widget build(BuildContext context) {
    if (!context.isWebLayout) {
      return child;
    }

    if (centerContent) {
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(padding: context.responsivePadding, child: child),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: context.responsivePadding, child: child),
      ),
    );
  }
}

/// Responsive form layout
class ResponsiveFormLayout extends StatelessWidget {
  final List<Widget> fields;
  final int? columns;
  final double spacing;
  final EdgeInsets? padding;

  const ResponsiveFormLayout({
    super.key,
    required this.fields,
    this.columns,
    this.spacing = 16,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final cols =
        columns ??
        (context.isMobile
            ? 1
            : context.isTablet
            ? 2
            : 3);

    return Padding(
      padding: padding ?? context.responsivePadding,
      child: GridView.count(
        crossAxisCount: cols,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: fields,
      ),
    );
  }
}

/// Responsive side-by-side layout
class ResponsiveSideBySide extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double spacing;
  final bool forceVertical;

  const ResponsiveSideBySide({
    super.key,
    required this.left,
    required this.right,
    this.spacing = 24,
    this.forceVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical = forceVertical || context.isMobile;

    if (isVertical) {
      return Column(
        children: [
          Expanded(child: left),
          SizedBox(height: spacing),
          Expanded(child: right),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        SizedBox(width: spacing),
        Expanded(child: right),
      ],
    );
  }
}

/// Responsive list layout
class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final EdgeInsets? padding;
  final double spacing;
  final bool shrinkWrap;
  final bool enableDesktopSpacing;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.physics,
    this.controller,
    this.padding,
    this.spacing = 12,
    this.shrinkWrap = false,
    this.enableDesktopSpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(SizedBox(height: spacing));
      }
    }

    return ListView(
      physics: physics,
      controller: controller,
      padding: padding ?? context.responsivePadding,
      shrinkWrap: shrinkWrap,
      children: items,
    );
  }
}

/// Responsive section with header and content
class ResponsiveSection extends StatelessWidget {
  final String title;
  final Widget content;
  final Widget? trailing;
  final VoidCallback? onHeaderTap;
  final bool collapsible;
  final bool initiallyExpanded;
  final EdgeInsets? padding;

  const ResponsiveSection({
    super.key,
    required this.title,
    required this.content,
    this.trailing,
    this.onHeaderTap,
    this.collapsible = false,
    this.initiallyExpanded = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? context.responsivePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onHeaderTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }
}

/// Responsive hero section
class ResponsiveHeroSection extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? imageWidget;
  final String? backgroundImageUrl;
  final Color? backgroundColor;
  final List<Widget>? actions;
  final double? minHeight;

  const ResponsiveHeroSection({
    super.key,
    this.title,
    this.subtitle,
    this.imageWidget,
    this.backgroundImageUrl,
    this.backgroundColor,
    this.actions,
    this.minHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight ?? 300),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.primaryColor,
        image: backgroundImageUrl != null
            ? DecorationImage(
                image: NetworkImage(backgroundImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
          ),
        ),
        padding: context.responsivePadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageWidget != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: SizedBox(
                  height: context.isWebLayout ? 150 : 100,
                  child: imageWidget,
                ),
              ),
            if (title != null)
              Text(
                title!,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  subtitle!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Wrap(spacing: 12, runSpacing: 12, children: actions!),
              ),
          ],
        ),
      ),
    );
  }
}
