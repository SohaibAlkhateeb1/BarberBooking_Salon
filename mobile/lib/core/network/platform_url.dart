import 'package:flutter/foundation.dart';

String getApiBaseUrl() {
  const apiUrl = String.fromEnvironment('API_URL');
  if (apiUrl.isNotEmpty) return apiUrl;
  if (kIsWeb) return 'https://barberbooking-salon.onrender.com';
  return 'https://barberbooking-salon.onrender.com';
}

String getFullImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http')) return imageUrl;
  return '${getApiBaseUrl()}$imageUrl';
}
