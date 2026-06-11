import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Modern UI decoration effects
class ModernDecoration {
  /// Glassmorphism effect with blur
  static BoxDecoration glassmorphism({
    Color color = Colors.white,
    double opacity = 0.1,
    double blur = 10,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.5,
      ),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Neumorphism effect
  static BoxDecoration neumorphism({
    Color backgroundColor = AppTheme.backgroundColor,
    Color shadowColor = Colors.black,
    bool isPressed = false,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: isPressed
          ? [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.1),
                blurRadius: 5,
                offset: const Offset(2, 2),
              ),
            ]
          : [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.1),
                blurRadius: 15,
                offset: const Offset(5, 5),
              ),
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.7),
                blurRadius: 15,
                offset: const Offset(-5, -5),
              ),
            ],
    );
  }

  /// Gradient button decoration
  static BoxDecoration gradientButton({
    Color startColor = AppTheme.primaryColor,
    Color endColor = AppTheme.primaryDark,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [startColor, endColor],
      ),
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: startColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Modern card with shadow
  static BoxDecoration modernCard() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  /// Border decoration
  static BoxDecoration borderDecoration({
    Color borderColor = AppTheme.textSecondary,
    double borderWidth = 1,
    double radius = 12,
  }) {
    return BoxDecoration(
      border: Border.all(color: borderColor, width: borderWidth),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Web-specific effects and animations
class WebEffects {
  /// Hover scale effect
  static Widget hoverScale({
    required Widget child,
    double scale = 1.05,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return MouseRegion(
      child: TweenAnimationBuilder(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: duration,
        builder: (context, value, widget) {
          return Transform.scale(scale: value, child: child);
        },
      ),
    );
  }

  /// Hover elevation effect
  static Widget hoverElevation({
    required Widget child,
    double elevationDifference = 8,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return MouseRegion(child: child);
  }

  /// Gradient text effect
  static ShaderMask gradientText({
    required Widget child,
    Color startColor = AppTheme.primaryColor,
    Color endColor = AppTheme.primaryDark,
  }) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [startColor, endColor],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(bounds),
      child: child,
    );
  }
}

/// Skeleton loader for content placeholders
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final ShapeBorder shape;
  final Duration animationDuration;

  const SkeletonLoader({
    super.key,
    required this.width,
    required this.height,
    this.shape = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
    ),
    this.animationDuration = const Duration(milliseconds: 1500),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: ShapeDecoration(shape: widget.shape, color: Colors.grey[300]),
      child: ShaderMask(
        shaderCallback: (bounds) {
          final position = Tween<double>(begin: -2, end: 2).evaluate(
            CurvedAnimation(parent: _animationController, curve: Curves.linear),
          );
          return LinearGradient(
            begin: Alignment(-3, 0),
            end: Alignment(3, 0),
            tileMode: TileMode.clamp,
            colors: [Colors.grey[300]!, Colors.grey[200]!, Colors.grey[300]!],
            stops: [position - 0.5, position, position + 0.5],
          ).createShader(bounds);
        },
        child: Container(color: Colors.grey[300]),
      ),
    );
  }
}

/// Grid skeleton loader
class SkeletonGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;

  const SkeletonGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 16,
    this.crossAxisSpacing = 16,
    this.childAspectRatio = 0.75,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: mainAxisSpacing,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        itemCount,
        (index) => Container(
          decoration: ModernDecoration.modernCard(),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SkeletonLoader(
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
              const SizedBox(height: 8),
              SkeletonLoader(width: double.infinity, height: 12),
              const SizedBox(height: 8),
              SkeletonLoader(width: 100, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// List skeleton loader
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double spacing;
  final EdgeInsets? padding;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.spacing = 12,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: itemCount,
      separatorBuilder: (_, _) => SizedBox(height: spacing),
      padding: padding ?? const EdgeInsets.all(16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight,
          decoration: ModernDecoration.modernCard(),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SkeletonLoader(width: itemHeight - 24, height: itemHeight - 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SkeletonLoader(width: double.infinity, height: 12),
                    const SizedBox(height: 8),
                    SkeletonLoader(width: 150, height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer text effect
class ShimmerText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Color shimmerColor;

  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.shimmerColor = AppTheme.primaryLight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(
        shadows: [Shadow(color: shimmerColor, blurRadius: 2)],
      ),
    );
  }
}
