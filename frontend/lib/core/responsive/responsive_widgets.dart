import 'package:flutter/material.dart';

import './responsive_config.dart';

/// Responsive Container that adapts to screen size
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final double? maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: padding ?? context.responsivePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxWidth ?? context.maxContentWidth,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Responsive Grid View with adaptive columns
class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double spacing;
  final ScrollPhysics? physics;
  final ScrollController? controller;
  final bool shrinkWrap;
  final EdgeInsets? padding;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.largeDesktopColumns = 6,
    this.spacing = 16,
    this.physics,
    this.controller,
    this.shrinkWrap = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    int columns;
    if (context.isMobile) {
      columns = mobileColumns;
    } else if (context.isTablet) {
      columns = tabletColumns;
    } else if (context.isDesktop) {
      columns = desktopColumns;
    } else {
      columns = largeDesktopColumns;
    }

    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: 0.75,
      physics: physics ?? const ScrollPhysics(),
      controller: controller,
      shrinkWrap: shrinkWrap,
      padding: padding ?? EdgeInsets.all(context.responsiveSpacing),
      children: children,
    );
  }
}

/// Responsive Sliver Grid View for CustomScrollView
class ResponsiveSliverGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final int largeDesktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const ResponsiveSliverGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.largeDesktopColumns = 6,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    int columns;
    if (context.isMobile) {
      columns = mobileColumns;
    } else if (context.isTablet) {
      columns = tabletColumns;
    } else if (context.isDesktop) {
      columns = desktopColumns;
    } else {
      columns = largeDesktopColumns;
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }
}

/// Responsive column layout
class ResponsiveColumnLayout extends StatelessWidget {
  final Widget mobileLayout;
  final Widget tabletLayout;
  final Widget desktopLayout;

  const ResponsiveColumnLayout({
    super.key,
    required this.mobileLayout,
    required this.tabletLayout,
    required this.desktopLayout,
  });

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return mobileLayout;
    } else if (context.isTablet) {
      return tabletLayout;
    } else {
      return desktopLayout;
    }
  }
}

/// Responsive Row/Column that adapts based on screen size
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool useColumn;

  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16,
    this.useColumn = false,
  });

  @override
  Widget build(BuildContext context) {
    final shouldUseColumn = useColumn || context.isMobile;
    final items = <Widget>[];

    for (int i = 0; i < children.length; i++) {
      items.add(Expanded(child: children[i]));
      if (i < children.length - 1) {
        items.add(
          SizedBox(
            width: shouldUseColumn ? 0 : spacing,
            height: shouldUseColumn ? spacing : 0,
          ),
        );
      }
    }

    if (shouldUseColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: items,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: items,
      );
    }
  }
}

/// Responsive Text widget for better typography scaling
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final bool softWrap;
  final TextOverflow overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
  });

  @override
  Widget build(BuildContext context) {
    final baseFontSize = style?.fontSize ?? 16;
    final responsiveFontSize = ResponsiveHelper.getResponsiveFontSize(
      context.screenWidth,
      baseFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        fontSize: responsiveFontSize,
      ),
      textAlign: textAlign,
      softWrap: softWrap,
      overflow: overflow,
    );
  }
}

/// Responsive button that adapts size based on screen
class ResponsiveButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;
  final bool isSmall;
  final IconData? icon;

  const ResponsiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isOutlined = false,
    this.isSmall = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final padding = isSmall
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
        : const EdgeInsets.symmetric(horizontal: 24, vertical: 12);

    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon), const SizedBox(width: 8)],
        Text(label),
      ],
    );

    if (isOutlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(padding: padding),
        child: child,
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(padding: padding),
        child: child,
      );
    }
  }
}

/// Responsive Spacer
class ResponsiveSpacer extends StatelessWidget {
  final bool horizontal;

  const ResponsiveSpacer({super.key, this.horizontal = true});

  @override
  Widget build(BuildContext context) {
    final spacing = context.responsiveSpacing;
    return SizedBox(
      width: horizontal ? spacing : 0,
      height: horizontal ? 0 : spacing,
    );
  }
}

/// Responsive Card with hover effect (desktop only)
class ResponsiveCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final bool enableHover;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.onTap,
    this.enableHover = true,
  });

  @override
  State<ResponsiveCard> createState() => _ResponsiveCardState();
}

class _ResponsiveCardState extends State<ResponsiveCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: _isHovered && widget.enableHover && context.isWebLayout
          ? 8
          : 2,
      child: Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: widget.child,
      ),
    );

    if (!context.isWebLayout || !widget.enableHover) {
      return GestureDetector(onTap: widget.onTap, child: card);
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform: _isHovered
              ? (Matrix4.identity()..translateByDouble(0, -8, 0, 1))
              : Matrix4.identity(),
          child: card,
        ),
      ),
    );
  }
}
