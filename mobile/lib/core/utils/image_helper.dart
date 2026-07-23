import 'dart:convert';
import 'package:flutter/material.dart';
import '../network/platform_url.dart';

class ImageHelper {
  static String getBaseUrl() => getApiBaseUrl();

  static String? getFullUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;
    if (imageUrl.startsWith('http')) return imageUrl;
    return '${getBaseUrl()}$imageUrl';
  }

  static Widget displayImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return placeholder ?? const SizedBox.shrink();
    }

    if (imageUrl.startsWith('data:image') || imageUrl.startsWith('/9j/') || imageUrl.startsWith('iVBOR')) {
      try {
        String b64 = imageUrl;
        if (b64.startsWith('data:')) b64 = b64.split(',')[1];
        final bytes = base64Decode(b64);
        final img = Image.memory(bytes, width: width, height: height, fit: fit);
        return borderRadius != null
            ? ClipRRect(borderRadius: borderRadius, child: img)
            : img;
      } catch (_) {}
    }

    final fullUrl = getFullUrl(imageUrl);
    if (fullUrl == null) {
      return placeholder ?? const SizedBox.shrink();
    }

    final img = Image.network(
      fullUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => errorWidget ?? placeholder ?? const SizedBox.shrink(),
    );
    return borderRadius != null
        ? ClipRRect(borderRadius: borderRadius, child: img)
        : img;
  }

  static ImageProvider? getImageProvider(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return null;

    if (imageUrl.startsWith('data:image') || imageUrl.startsWith('/9j/') || imageUrl.startsWith('iVBOR')) {
      try {
        String b64 = imageUrl;
        if (b64.startsWith('data:')) b64 = b64.split(',')[1];
        return MemoryImage(base64Decode(b64));
      } catch (_) {}
    }

    final fullUrl = getFullUrl(imageUrl);
    if (fullUrl != null) return NetworkImage(fullUrl);
    return null;
  }
}
