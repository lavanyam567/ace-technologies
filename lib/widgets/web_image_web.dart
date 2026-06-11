// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

final Set<String> _registeredViewTypes = <String>{};

Widget? buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (url.isEmpty) return null;

  final viewType = 'ace-product-image-${url.hashCode}-${fit.name}';
  if (_registeredViewTypes.add(viewType)) {
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final image = html.ImageElement()
        ..src = url
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.display = 'block'
        ..style.objectFit = _cssObjectFit(fit);
      image
        ..setAttribute('decoding', 'async')
        ..setAttribute('loading', 'lazy');
      image.onError.listen((_) {
        image.style.display = 'none';
      });
      return image;
    });
  }

  return Container(
    width: width,
    height: height,
    color: const Color(0xFF1E2A3A),
    child: HtmlElementView(viewType: viewType),
  );
}

String _cssObjectFit(BoxFit fit) {
  switch (fit) {
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitHeight:
    case BoxFit.fitWidth:
    case BoxFit.scaleDown:
      return 'contain';
    case BoxFit.none:
      return 'none';
    case BoxFit.cover:
      return 'cover';
  }
}
