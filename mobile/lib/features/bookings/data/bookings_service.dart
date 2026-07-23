import '../../../core/network/api_client.dart';

class BookingModel {
  final String id;
  final String barberName;
  final String shopName;
  final String shopLogoUrl;
  final String serviceName;
  final double servicePrice;
  final int serviceDuration;
  final String bookingDate;
  final String bookingTime;
  final double totalPrice;
  final double? finalPrice;
  final String status;
  final String? cancellationReason;
  final String address;
  final String? employeeName;
  final double averageRating;
  final int reviewCount;

  BookingModel({
    required this.id,
    required this.barberName,
    required this.shopName,
    required this.shopLogoUrl,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.bookingDate,
    required this.bookingTime,
    required this.totalPrice,
    this.finalPrice,
    required this.status,
    this.cancellationReason,
    required this.address,
    this.employeeName,
    required this.averageRating,
    required this.reviewCount,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] ?? '',
      barberName: json['barberName'] ?? '',
      shopName: json['shopName'] ?? '',
      shopLogoUrl: json['shopLogoUrl'] ?? '',
      serviceName: json['serviceName'] ?? '',
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      serviceDuration: json['serviceDuration'] ?? 0,
      bookingDate: json['bookingDate'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      status: json['status'] ?? '',
      cancellationReason: json['cancellationReason'],
      address: json['address'] ?? '',
      employeeName: json['employeeName'],
      averageRating: (json['averageRating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
    );
  }
}

class BookingDetailModel {
  final String id;
  final String bookingCode;
  final String barberProfileId;
  final String barberName;
  final String shopName;
  final String shopAddress;
  final String shopCity;
  final String serviceName;
  final double servicePrice;
  final int serviceDuration;
  final String bookingDate;
  final String bookingTime;
  final double totalPrice;
  final double? finalPrice;
  final String status;
  final String? cancellationReason;
  final String? notes;
  final String? paymentStatus;
  final String? employeeName;
  final String createdAt;
  final bool hasReview;

  BookingDetailModel({
    required this.id,
    required this.bookingCode,
    required this.barberProfileId,
    required this.barberName,
    required this.shopName,
    required this.shopAddress,
    required this.shopCity,
    required this.serviceName,
    required this.servicePrice,
    required this.serviceDuration,
    required this.bookingDate,
    required this.bookingTime,
    required this.totalPrice,
    this.finalPrice,
    required this.status,
    this.cancellationReason,
    this.notes,
    this.paymentStatus,
    this.employeeName,
    required this.createdAt,
    this.hasReview = false,
  });

  factory BookingDetailModel.fromJson(Map<String, dynamic> json) {
    return BookingDetailModel(
      id: json['id'] ?? '',
      bookingCode: json['bookingCode'] ?? '',
      barberProfileId: json['barberProfileId'] ?? '',
      barberName: json['barberName'] ?? '',
      shopName: json['shopName'] ?? '',
      shopAddress: json['shopAddress'] ?? '',
      shopCity: json['shopCity'] ?? '',
      serviceName: json['serviceName'] ?? '',
      servicePrice: (json['servicePrice'] ?? 0).toDouble(),
      serviceDuration: json['serviceDuration'] ?? 0,
      bookingDate: json['bookingDate'] ?? '',
      bookingTime: json['bookingTime'] ?? '',
      totalPrice: (json['totalPrice'] ?? 0).toDouble(),
      finalPrice: json['finalPrice']?.toDouble(),
      status: json['status'] ?? '',
      cancellationReason: json['cancellationReason'],
      notes: json['notes'],
      paymentStatus: json['paymentStatus'],
      employeeName: json['employeeName'],
      createdAt: json['createdAt'] ?? '',
      hasReview: json['hasReview'] ?? false,
    );
  }
}

class AvailableSlotModel {
  final String time;
  final String period;
  final bool isAvailable;

  AvailableSlotModel({
    required this.time,
    required this.period,
    required this.isAvailable,
  });

  factory AvailableSlotModel.fromJson(Map<String, dynamic> json) {
    return AvailableSlotModel(
      time: json['time'] ?? '',
      period: json['period'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
    );
  }
}

class BookingsService {
  final ApiClient _apiClient;

  BookingsService(this._apiClient);

  Future<BookingDetailModel> createBooking({
    required String barberProfileId,
    required String barberServiceId,
    required String bookingDate,
    required String bookingTime,
    String? notes,
    String? promoCode,
    List<String>? serviceIds,
    String? employeeId,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/bookings',
      data: {
        'barberProfileId': barberProfileId,
        'barberServiceId': barberServiceId,
        'bookingDate': bookingDate,
        'bookingTime': bookingTime,
        if (serviceIds != null && serviceIds.isNotEmpty) 'serviceIds': serviceIds,
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
        if (notes != null) 'notes': notes,
        if (promoCode != null) 'promoCode': promoCode,
      },
    );

    return BookingDetailModel.fromJson(response.data);
  }

  Future<List<BookingModel>> getMyBookings({String? status}) async {
    final response = await _apiClient.dio.get(
      '/api/bookings/my',
      queryParameters: {
        if (status != null) 'status': status,
      },
    );

    final data = response.data;
    if (data is List) {
      return data.map((e) => BookingModel.fromJson(e)).toList();
    }
    return [];
  }

  Future<BookingDetailModel> getBookingDetail(String id) async {
    final response = await _apiClient.dio.get('/api/bookings/$id');
    return BookingDetailModel.fromJson(response.data);
  }

  Future<BookingDetailModel> rescheduleBooking({
    required String id,
    required String newDate,
    required String newTime,
  }) async {
    final response = await _apiClient.dio.put(
      '/api/bookings/$id/reschedule',
      data: {
        'newDate': newDate,
        'newTime': newTime,
      },
    );

    return BookingDetailModel.fromJson(response.data);
  }

  Future<void> cancelBooking({
    required String id,
    String? reason,
  }) async {
    await _apiClient.dio.put(
      '/api/bookings/$id/cancel',
      data: {
        if (reason != null) 'reason': reason,
      },
    );
  }

  Future<List<AvailableSlotModel>> getAvailableSlots({
    required String barberProfileId,
    required String date,
    String? employeeId,
    String scope = 'booking',
    int durationInMinutes = 30,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/bookings/available-slots',
      queryParameters: {
        'barberProfileId': barberProfileId,
        'date': date,
        if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
        'scope': scope,
        'durationInMinutes': durationInMinutes,
      },
    );

    final slots = response.data['slots'] as List? ?? [];
    return slots.map((e) => AvailableSlotModel.fromJson(e)).toList();
  }

  Future<void> addReview({
    required String bookingId,
    required int rating,
    String? comment,
  }) async {
    await _apiClient.dio.post(
      '/api/bookings/$bookingId/review',
      data: {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
    );
  }
}
