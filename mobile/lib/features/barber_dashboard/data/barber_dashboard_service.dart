import '../../../core/network/api_client.dart';

class BarberDashboardModel {
  final String shopName;
  final int todayBookingsCount;
  final double todayRevenue;
  final double averageRating;
  final int reviewCount;
  final int activeClients;
  final List<BarberBookingModel> recentBookings;
  final List<WeeklyRevenueModel> weeklyRevenue;

  BarberDashboardModel({
    required this.shopName,
    required this.todayBookingsCount,
    required this.todayRevenue,
    required this.averageRating,
    required this.reviewCount,
    required this.activeClients,
    required this.recentBookings,
    required this.weeklyRevenue,
  });

  factory BarberDashboardModel.fromJson(Map<String, dynamic> json) {
    return BarberDashboardModel(
      shopName: json['shopName'] ?? '',
      todayBookingsCount: json['todayBookingsCount'] ?? 0,
      todayRevenue: (json['todayRevenue'] ?? 0).toDouble(),
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      activeClients: json['activeClients'] ?? 0,
      recentBookings: (json['recentBookings'] as List<dynamic>?)
              ?.map((e) => BarberBookingModel.fromJson(e))
              .toList() ??
          [],
      weeklyRevenue: (json['weeklyRevenue'] as List<dynamic>?)
              ?.map((e) => WeeklyRevenueModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WeeklyRevenueModel {
  final String day;
  final double revenue;

  WeeklyRevenueModel({required this.day, required this.revenue});

  factory WeeklyRevenueModel.fromJson(Map<String, dynamic> json) {
    return WeeklyRevenueModel(
      day: json['day'] ?? '',
      revenue: (json['revenue'] ?? 0).toDouble(),
    );
  }
}

class BarberBookingModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String serviceName;
  final int serviceDuration;
  final double? servicePrice;
  final String bookingDate;
  final String bookingTime;
  final double totalPrice;
  final double? finalPrice;
  final String status;
  final String? notes;
  final String? cancellationReason;
  final String? paymentStatus;
  final String? paymentMethod;
  final String? promoCode;
  final double? discountAmount;
  final String? employeeId;
  final String? employeeName;
  final String createdAt;
  final String? startedAt;
  final String? serviceCompletedAt;
  final int serviceDurationMinutes;

  BarberBookingModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.serviceName,
    required this.serviceDuration,
    this.servicePrice,
    required this.bookingDate,
    required this.bookingTime,
    required this.totalPrice,
    this.finalPrice,
    required this.status,
    this.notes,
    this.cancellationReason,
    this.paymentStatus,
    this.paymentMethod,
    this.promoCode,
    this.discountAmount,
    this.employeeId,
    this.employeeName,
    required this.createdAt,
    this.startedAt,
    this.serviceCompletedAt,
    this.serviceDurationMinutes = 30,
  });

  factory BarberBookingModel.fromJson(Map<String, dynamic> json) {
    return BarberBookingModel(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      serviceName: json['serviceName'] ?? '',
      serviceDuration: json['serviceDuration'] ?? 0,
      servicePrice: json['servicePrice']?.toDouble(),
      bookingDate: json['bookingDate'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      status: json['status'] ?? '',
      notes: json['notes'],
      cancellationReason: json['cancellationReason'],
      paymentStatus: json['paymentStatus'],
      paymentMethod: json['paymentMethod'],
      promoCode: json['promoCode'],
      discountAmount: json['discountAmount']?.toDouble(),
      employeeId: json['employeeId'],
      employeeName: json['employeeName'],
      createdAt: json['createdAt'] ?? '',
      startedAt: json['startedAt'],
      serviceCompletedAt: json['serviceCompletedAt'],
      serviceDurationMinutes: json['serviceDurationMinutes'] ?? json['serviceDuration'] ?? 30,
    );
  }

  double get effectivePrice => finalPrice ?? totalPrice;
  bool get hasDiscount => discountAmount != null && discountAmount! > 0;
}

class BarberServiceModel {
  final String id;
  final String name;
  final double price;
  final int durationInMinutes;

  BarberServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationInMinutes,
  });

  factory BarberServiceModel.fromJson(Map<String, dynamic> json) {
    return BarberServiceModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      durationInMinutes: json['durationInMinutes'] ?? 0,
    );
  }
}

class WorkingHourModel2 {
  final String dayName;
  final bool isOpen;
  final String openTime;
  final String closeTime;

  WorkingHourModel2({
    required this.dayName,
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory WorkingHourModel2.fromJson(Map<String, dynamic> json) {
    return WorkingHourModel2(
      dayName: json['dayName'] ?? '',
      isOpen: json['isOpen'] ?? false,
      openTime: json['openTime'] ?? '',
      closeTime: json['closeTime'] ?? '',
    );
  }
}

class BarberDashboardService {
  final ApiClient _apiClient;

  BarberDashboardService(this._apiClient);

  Future<BarberDashboardModel> getDashboard() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard');
    return BarberDashboardModel.fromJson(response.data);
  }

  Future<List<BarberBookingModel>> getBookings({String? status, String? date}) async {
    final response = await _apiClient.dio.get(
      '/api/barber/dashboard/bookings',
      queryParameters: {
        if (status != null) 'status': status,
        if (date != null) 'date': date,
      },
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => BarberBookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<BarberBookingModel> getBookingDetail(String id) async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/bookings/$id');
    return BarberBookingModel.fromJson(response.data);
  }

  Future<void> completeBooking(String id) async {
    await _apiClient.dio.put('/api/barber/dashboard/bookings/$id/complete');
  }

  Future<void> acceptBooking(String id) async {
    await _apiClient.dio.put('/api/barber/dashboard/bookings/$id/accept');
  }

  Future<void> rejectBooking(String id, {String? reason}) async {
    await _apiClient.dio.put(
      '/api/barber/dashboard/bookings/$id/reject',
      data: {'reason': reason},
    );
  }

  Future<void> startBooking(String id) async {
    await _apiClient.dio.put('/api/barber/dashboard/bookings/$id/start');
  }

  Future<void> requestPayment(String id) async {
    await _apiClient.dio.put('/api/barber/dashboard/bookings/$id/request-payment');
  }

  Future<void> noShowBooking(String id) async {
    await _apiClient.dio.put('/api/barber/dashboard/bookings/$id/no-show');
  }

  Future<void> rescheduleBooking(String id, {required String newDate, required String newTime}) async {
    await _apiClient.dio.put(
      '/api/barber/dashboard/bookings/$id/reschedule',
      data: {'newDate': newDate, 'newTime': newTime},
    );
  }

  Future<List<BarberServiceModel>> getServices() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/services');
    final data = response.data;
    if (data is List) {
      return data.map((e) => BarberServiceModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<List<BlockedCustomer>> getBlockedCustomers() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/customers/blocked');
    final data = response.data;
    if (data is List) {
      return data.map((e) => BlockedCustomer.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> unblockCustomer(String customerId) async {
    await _apiClient.dio.put('/api/barber/dashboard/customers/$customerId/unblock');
  }

  Future<BarberServiceModel> addService({required String name, required double price, required int duration}) async {
    final response = await _apiClient.dio.post(
      '/api/barber/dashboard/services',
      data: {'name': name, 'price': price, 'durationInMinutes': duration},
    );
    return BarberServiceModel.fromJson(response.data);
  }

  Future<void> updateService(String id, {required String name, required double price, required int duration}) async {
    await _apiClient.dio.put(
      '/api/barber/dashboard/services/$id',
      data: {'name': name, 'price': price, 'durationInMinutes': duration},
    );
  }

  Future<void> deleteService(String id) async {
    await _apiClient.dio.delete('/api/barber/dashboard/services/$id');
  }

  Future<List<WorkingHourModel2>> getSchedule() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/schedule');
    final data = response.data;
    if (data is List) {
      return data.map((e) => WorkingHourModel2.fromJson(e)).toList();
    }
    return [];
  }

  Future<void> updateSchedule(List<Map<String, dynamic>> schedule) async {
    await _apiClient.dio.put(
      '/api/barber/dashboard/schedule',
      data: schedule,
    );
  }

  Future<BarberProfileInfoModel> getProfileInfo() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/profile');
    return BarberProfileInfoModel.fromJson(response.data);
  }

  Future<void> updateProfileInfo({
    String? shopName,
    String? shopDescription,
    String? city,
    String? address,
    double? latitude,
    double? longitude,
    String? whatsappNumber,
    String? instagramHandle,
    String? tiktokHandle,
    String? ownerName,
    String? email,
    String? shopLogoUrl,
    String? coverImageUrl,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (shopName != null) body['shopName'] = shopName;
    if (shopDescription != null) body['shopDescription'] = shopDescription;
    if (city != null) body['city'] = city;
    if (address != null) body['address'] = address;
    if (latitude != null) body['latitude'] = latitude;
    if (longitude != null) body['longitude'] = longitude;
    if (whatsappNumber != null) body['whatsappNumber'] = whatsappNumber;
    if (instagramHandle != null) body['instagramHandle'] = instagramHandle;
    if (tiktokHandle != null) body['tiktokHandle'] = tiktokHandle;
    if (ownerName != null) body['ownerName'] = ownerName;
    if (email != null) body['email'] = email;
    if (shopLogoUrl != null) body['shopLogoUrl'] = shopLogoUrl;
    if (coverImageUrl != null) body['coverImageUrl'] = coverImageUrl;
    if (profileImageUrl != null) body['profileImageUrl'] = profileImageUrl;

    await _apiClient.dio.put('/api/barber/dashboard/profile', data: body);
  }

  Future<Map<String, String>> uploadImage(String base64Image, String imageType) async {
    final response = await _apiClient.dio.post('/api/barber/dashboard/upload-image', data: {
      'imageBase64': base64Image,
      'imageType': imageType,
    });
    final data = response.data;
    return {
      'profileImageUrl': data['profileImageUrl'] ?? '',
      'shopLogoUrl': data['shopLogoUrl'] ?? '',
      'coverImageUrl': data['coverImageUrl'] ?? '',
    };
  }

  Future<BarberReviewsModel> getBarberReviews() async {
    final response = await _apiClient.dio.get('/api/barber/dashboard/reviews');
    return BarberReviewsModel.fromJson(response.data);
  }
}

class BarberProfileInfoModel {
  final String shopName;
  final String? shopDescription;
  final String? shopLogoUrl;
  final String? coverImageUrl;
  final String city;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? whatsappNumber;
  final String? instagramHandle;
  final String? tiktokHandle;
  final String ownerName;
  final String phoneNumber;
  final String? email;
  final String? profileImageUrl;

  BarberProfileInfoModel({
    required this.shopName,
    this.shopDescription,
    this.shopLogoUrl,
    this.coverImageUrl,
    required this.city,
    required this.address,
    this.latitude,
    this.longitude,
    this.whatsappNumber,
    this.instagramHandle,
    this.tiktokHandle,
    required this.ownerName,
    required this.phoneNumber,
    this.email,
    this.profileImageUrl,
  });

  factory BarberProfileInfoModel.fromJson(Map<String, dynamic> json) {
    return BarberProfileInfoModel(
      shopName: json['shopName'] ?? '',
      shopDescription: json['shopDescription'],
      shopLogoUrl: json['shopLogoUrl'],
      coverImageUrl: json['coverImageUrl'],
      city: json['city'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      whatsappNumber: json['whatsappNumber'],
      instagramHandle: json['instagramHandle'],
      tiktokHandle: json['tiktokHandle'],
      ownerName: json['ownerName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      email: json['email'],
      profileImageUrl: json['profileImageUrl'],
    );
  }
}

class BarberReviewsModel {
  final double averageRating;
  final int reviewCount;
  final List<BarberReviewItem> reviews;

  BarberReviewsModel({
    required this.averageRating,
    required this.reviewCount,
    required this.reviews,
  });

  factory BarberReviewsModel.fromJson(Map<String, dynamic> json) {
    return BarberReviewsModel(
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => BarberReviewItem.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class BarberReviewItem {
  final String id;
  final String customerName;
  final int rating;
  final String comment;
  final DateTime createdAt;

  BarberReviewItem({
    required this.id,
    required this.customerName,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory BarberReviewItem.fromJson(Map<String, dynamic> json) {
    return BarberReviewItem(
      id: json['id'] ?? '',
      customerName: json['customerName'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class BlockedCustomer {
  final String id;
  final String fullName;
  final String phoneNumber;
  final int noShowCount;
  final String? blockReason;
  final DateTime? bookingBlockedAt;

  BlockedCustomer({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.noShowCount,
    this.blockReason,
    this.bookingBlockedAt,
  });

  factory BlockedCustomer.fromJson(Map<String, dynamic> json) {
    return BlockedCustomer(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      noShowCount: json['noShowCount'] ?? 0,
      blockReason: json['blockReason'],
      bookingBlockedAt: json['bookingBlockedAt'] != null
          ? DateTime.tryParse(json['bookingBlockedAt'])
          : null,
    );
  }
}
