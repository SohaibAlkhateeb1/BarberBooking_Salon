import '../../../core/network/api_client.dart';

class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int durationInMinutes;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationInMinutes,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationInMinutes: json['durationInMinutes'] ?? 0,
    );
  }
}

class BarberModel {
  final String id;
  final String shopName;
  final String shopDescription;
  final String shopLogoUrl;
  final String? coverImageUrl;
  final String city;
  final String address;
  final String ownerName;
  final double averageRating;
  final int reviewCount;
  final List<ServiceModel> services;
  final bool isOpen;
  final double? latitude;
  final double? longitude;
  final double? distanceKm;

  BarberModel({
    required this.id,
    required this.shopName,
    required this.shopDescription,
    required this.shopLogoUrl,
    this.coverImageUrl,
    required this.city,
    required this.address,
    required this.ownerName,
    required this.averageRating,
    required this.reviewCount,
    required this.services,
    required this.isOpen,
    this.latitude,
    this.longitude,
    this.distanceKm,
  });

  factory BarberModel.fromJson(Map<String, dynamic> json) {
    return BarberModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      shopDescription: json['shopDescription'] ?? '',
      shopLogoUrl: json['shopLogoUrl'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      ownerName: json['ownerName'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isOpen: json['isOpen'] ?? false,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      distanceKm: json['distanceKm'] != null ? (json['distanceKm']).toDouble() : null,
    );
  }
}

class WorkingHourModel {
  final int dayOfWeek;
  final String dayName;
  final String openTime;
  final String closeTime;
  final bool isOpen;

  WorkingHourModel({
    required this.dayOfWeek,
    required this.dayName,
    required this.openTime,
    required this.closeTime,
    required this.isOpen,
  });

  factory WorkingHourModel.fromJson(Map<String, dynamic> json) {
    return WorkingHourModel(
      dayOfWeek: json['dayOfWeek'] ?? 0,
      dayName: json['dayName'] ?? '',
      openTime: json['openTime'] ?? '',
      closeTime: json['closeTime'] ?? '',
      isOpen: json['isOpen'] ?? false,
    );
  }
}

class ReviewModel {
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id']?.toString() ?? '',
      customerName: json['customerName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class PortfolioImageModel {
  final String id;
  final String imageUrl;
  final String? caption;
  final int sortOrder;

  PortfolioImageModel({
    required this.id,
    required this.imageUrl,
    this.caption,
    required this.sortOrder,
  });

  factory PortfolioImageModel.fromJson(Map<String, dynamic> json) {
    return PortfolioImageModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class EmployeeModel {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileImageUrl;

  EmployeeModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileImageUrl,
  });

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class BarberDetailModel {
  final String id;
  final String shopName;
  final String shopDescription;
  final String shopLogoUrl;
  final String? coverImageUrl;
  final String? profileImageUrl;
  final String city;
  final String address;
  final String ownerName;
  final double averageRating;
  final int reviewCount;
  final List<ServiceModel> services;
  final bool isOpen;
  final List<WorkingHourModel> workingHours;
  final List<ReviewModel> reviews;
  final List<PortfolioImageModel> portfolioImages;
  final List<EmployeeModel> employees;
  final double? latitude;
  final double? longitude;

  BarberDetailModel({
    required this.id,
    required this.shopName,
    required this.shopDescription,
    required this.shopLogoUrl,
    this.coverImageUrl,
    this.profileImageUrl,
    required this.city,
    required this.address,
    required this.ownerName,
    required this.averageRating,
    required this.reviewCount,
    required this.services,
    required this.isOpen,
    required this.workingHours,
    required this.reviews,
    this.portfolioImages = const [],
    this.employees = const [],
    this.latitude,
    this.longitude,
  });

  factory BarberDetailModel.fromJson(Map<String, dynamic> json) {
    return BarberDetailModel(
      id: json['id']?.toString() ?? '',
      shopName: json['shopName'] ?? '',
      shopDescription: json['shopDescription'] ?? '',
      shopLogoUrl: json['shopLogoUrl'] ?? '',
      coverImageUrl: json['coverImageUrl'],
      profileImageUrl: json['profileImageUrl'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      ownerName: json['ownerName'] ?? '',
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      services: (json['services'] as List<dynamic>?)
              ?.map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isOpen: json['isOpen'] ?? false,
      workingHours: (json['workingHours'] as List<dynamic>?)
              ?.map((e) => WorkingHourModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      portfolioImages: (json['portfolioImages'] as List<dynamic>?)
              ?.map((e) => PortfolioImageModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      employees: (json['employees'] as List<dynamic>?)
              ?.map((e) => EmployeeModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latitude: json['latitude'] != null ? (json['latitude']).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude']).toDouble() : null,
    );
  }
}

class BarbersService {
  final ApiClient _apiClient;

  BarbersService(this._apiClient);

  Future<List<BarberModel>> getAllBarbers({String? city, String? search, double? minRating, String? priceCategory}) async {
    final queryParams = <String, dynamic>{};
    if (city != null && city.isNotEmpty) {
      queryParams['city'] = city;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    if (minRating != null) {
      queryParams['minRating'] = minRating;
    }
    if (priceCategory != null && priceCategory.isNotEmpty) {
      queryParams['priceCategory'] = priceCategory;
    }

    final response = await _apiClient.dio.get(
      '/api/barbers',
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    final data = response.data;
    if (data is List) {
      return data
          .map((e) => BarberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<BarberDetailModel> getBarberById(String id) async {
    final response = await _apiClient.dio.get('/api/barbers/$id');

    return BarberDetailModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<BarberModel>> getNearbyBarbers({
    required double latitude,
    required double longitude,
    double radiusKm = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/barbers/nearby',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radiusKm': radiusKm,
      },
    );

    final data = response.data;
    if (data is List) {
      return data
          .map((e) => BarberModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
