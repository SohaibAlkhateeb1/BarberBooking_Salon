import 'package:flutter/foundation.dart';

String getApiBaseUrl() {
  const apiUrl = String.fromEnvironment('API_URL');
  if (apiUrl.isNotEmpty) return apiUrl;
  if (kIsWeb) return 'http://localhost:5170';
  return 'http://localhost:5170';
}

String getFullImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  return '${getApiBaseUrl()}$imageUrl';
}
