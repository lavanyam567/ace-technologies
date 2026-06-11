import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'web_image_stub.dart'
    if (dart.library.html) 'web_image_web.dart'
    as web_image;

class AceImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AceImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedUrl = url.trim().replaceAll(' ', '%20');

    final webImg = web_image.buildWebImage(
      url: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
    );
    if (webImg != null) {
      return _clipIfNeeded(webImg);
    }

    final img = CachedNetworkImage(
      imageUrl: normalizedUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          _ImagePlaceholder(width: width, height: height),
      errorWidget: (context, url, error) =>
          _ImageError(width: width, height: height),
    );

    return _clipIfNeeded(img);
  }

  Widget _clipIfNeeded(Widget child) {
    if (borderRadius == null) return child;
    return ClipRRect(borderRadius: borderRadius!, child: child);
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1E2A3A),
      child: const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF1D9E75),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _ImageError extends StatelessWidget {
  const _ImageError({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: const Color(0xFF1E2A3A),
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: Color(0xFF1D9E75),
        size: 32,
      ),
    );
  }
}
