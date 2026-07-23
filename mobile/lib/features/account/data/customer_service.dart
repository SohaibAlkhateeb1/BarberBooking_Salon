import '../../../core/network/api_client.dart';

class UserProfile {
  final String id;
  final String fullName;
  final String phoneNumber;
  final String? email;
  final String? profileImageUrl;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String role;

  UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    this.email,
    this.profileImageUrl,
    this.city,
    this.latitude,
    this.longitude,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
      city: json['city'],
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      role: json['role'] ?? '',
    );
  }
}

class FavoriteModel {
  final String id;
  final String shopName;
  final String city;
  final String address;
  final String ownerName;
  final double averageRating;
  final int reviewCount;
  final List<dynamic> services;
  final bool isOpen;

  FavoriteModel({
    required this.id,
    required this.shopName,
    required this.city,
    required this.address,
    required this.ownerName,
    required this.averageRating,
    required this.reviewCount,
    required this.services,
    required this.isOpen,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      ownerName: json['ownerName'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      services: json['services'] ?? [],
      isOpen: json['isOpen'] ?? false,
    );
  }
}

class MyReviewModel {
  final String id;
  final String barberName;
  final String shopName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  MyReviewModel({
    required this.id,
    required this.barberName,
    required this.shopName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory MyReviewModel.fromJson(Map<String, dynamic> json) {
    return MyReviewModel(
      id: json['id']?.toString() ?? '',
      barberName: json['barberName'] ?? '',
      shopName: json['shopName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class CustomerService {
  final ApiClient _apiClient;

  CustomerService(this._apiClient);

  Future<UserProfile> getProfile() async {
    final response = await _apiClient.dio.get('/api/customer/profile');
    return UserProfile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? profileImageUrl,
    String? city,
    double? latitude,
    double? longitude,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['fullName'] = fullName;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (email != null) body['email'] = email;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;
    if (city != null) body['city'] = city;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;

    await _apiClient.dio.put('/api/customer/profile', data: body);
  }

  Future<String> uploadImage(String base64Image) async {
    final response = await _apiClient.dio.post('/api/customer/upload-image', data: {
      'imageBase64': base64Image,
    });
    return response.data['profileImageUrl'] ?? '';
  }

  Future<List<FavoriteModel>> getFavorites() async {
    final response = await _apiClient.dio.get('/api/customer/favorites');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => FavoriteModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<void> addFavorite(String barberProfileId) async {
    await _apiClient.dio.post('/api/customer/favorites/$barberProfileId');
  }

  Future<void> removeFavorite(String barberProfileId) async {
    await _apiClient.dio.delete('/api/customer/favorites/$barberProfileId');
  }

  Future<bool> checkFavorite(String barberProfileId) async {
    final response = await _apiClient.dio.get('/api/customer/favorites/check/$barberProfileId');
    return response.data['isFavorite'] ?? false;
  }

  Future<List<MyReviewModel>> getMyReviews() async {
    final response = await _apiClient.dio.get('/api/customer/reviews');
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => MyReviewModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}