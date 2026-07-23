import '../network/api_client.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String nameArabic;
  final String description;
  final double monthlyPrice;
  final double yearlyPrice;
  final int maxServices;
  final int maxPhotos;
  final int maxBookingsPerMonth;
  final int maxEmployees;
  final String analyticsLevel;
  final bool hasPromoCodes;
  final bool hasPrioritySupport;
  final bool isActive;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.description,
    required this.monthlyPrice,
    required this.yearlyPrice,
    required this.maxServices,
    required this.maxPhotos,
    required this.maxBookingsPerMonth,
    required this.maxEmployees,
    required this.analyticsLevel,
    required this.hasPromoCodes,
    required this.hasPrioritySupport,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      nameArabic: json['nameArabic'] ?? '',
      description: json['description'] ?? '',
      monthlyPrice: (json['monthlyPrice'] ?? 0).toDouble(),
      yearlyPrice: (json['yearlyPrice'] ?? 0).toDouble(),
      maxServices: json['maxServices'] ?? 0,
      maxPhotos: json['maxPhotos'] ?? 0,
      maxBookingsPerMonth: json['maxBookingsPerMonth'] ?? 0,
      maxEmployees: json['maxEmployees'] ?? 0,
      analyticsLevel: json['analyticsLevel'] ?? 'none',
      hasPromoCodes: json['hasPromoCodes'] ?? false,
      hasPrioritySupport: json['hasPrioritySupport'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  int get discountPercentage => monthlyPrice > 0
      ? ((1 - yearlyPrice / (monthlyPrice * 12)) * 100).round()
      : 0;

  String get maxServicesText => maxServices < 0 ? 'غير محدود' : '$maxServices';
  String get maxPhotosText => maxPhotos < 0 ? 'غير محدود' : '$maxPhotos';
  String get maxBookingsText => maxBookingsPerMonth < 0 ? 'غير محدود' : '$maxBookingsPerMonth';
  String get maxEmployeesText => maxEmployees < 0 ? 'غير محدود' : '$maxEmployees';
}

class CurrentSubscription {
  final String subscriptionId;
  final String planId;
  final String planName;
  final String planNameArabic;
  final double amountPaid;
  final String paymentMethod;
  final String status;
  final bool isYearly;
  final DateTime startDate;
  final DateTime endDate;
  final int daysRemaining;
  final bool isExpiringSoon;
  final bool isExpired;
  final bool isCancelPending;
  final int maxServices;
  final int maxPhotos;
  final int maxBookingsPerMonth;
  final int maxEmployees;
  final String analyticsLevel;
  final bool hasPromoCodes;
  final bool hasPrioritySupport;
  final int currentServicesCount;
  final int currentPhotosCount;
  final int currentBookingsCount;
  final int currentEmployeesCount;
  final String bookingLimitStatus;

  CurrentSubscription({
    required this.subscriptionId,
    required this.planId,
    required this.planName,
    required this.planNameArabic,
    required this.amountPaid,
    required this.paymentMethod,
    required this.status,
    required this.isYearly,
    required this.startDate,
    required this.endDate,
    required this.daysRemaining,
    required this.isExpiringSoon,
    required this.isExpired,
    this.isCancelPending = false,
    required this.maxServices,
    required this.maxPhotos,
    required this.maxBookingsPerMonth,
    required this.maxEmployees,
    required this.analyticsLevel,
    required this.hasPromoCodes,
    required this.hasPrioritySupport,
    required this.currentServicesCount,
    required this.currentPhotosCount,
    required this.currentBookingsCount,
    required this.currentEmployeesCount,
    required this.bookingLimitStatus,
  });

  factory CurrentSubscription.fromJson(Map<String, dynamic> json) {
    final status = json['status'] ?? '';
    final endDate = DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String());
    final now = DateTime.now();
    final isExpired = status == 'expired' || (status == 'cancel_pending' && endDate.isBefore(now));
    final daysRemaining = endDate.difference(now).inDays;

    return CurrentSubscription(
      subscriptionId: json['subscriptionId'] ?? '',
      planId: json['planId'] ?? '',
      planName: json['planName'] ?? '',
      planNameArabic: json['planNameArabic'] ?? '',
      amountPaid: (json['amountPaid'] ?? 0).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: status,
      isYearly: json['isYearly'] ?? false,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: endDate,
      daysRemaining: daysRemaining > 0 ? daysRemaining : 0,
      isExpiringSoon: !isExpired && daysRemaining <= 7 && daysRemaining > 0,
      isExpired: isExpired,
      isCancelPending: status == 'cancel_pending' && !isExpired,
      maxServices: json['maxServices'] ?? 0,
      maxPhotos: json['maxPhotos'] ?? 0,
      maxBookingsPerMonth: json['maxBookingsPerMonth'] ?? 0,
      maxEmployees: json['maxEmployees'] ?? 0,
      analyticsLevel: json['analyticsLevel'] ?? 'none',
      hasPromoCodes: json['hasPromoCodes'] ?? false,
      hasPrioritySupport: json['hasPrioritySupport'] ?? false,
      currentServicesCount: json['currentServicesCount'] ?? 0,
      currentPhotosCount: json['currentPhotosCount'] ?? 0,
      currentBookingsCount: json['currentBookingsCount'] ?? 0,
      currentEmployeesCount: json['currentEmployeesCount'] ?? 0,
      bookingLimitStatus: json['bookingLimitStatus'] ?? 'normal',
    );
  }

  double get servicesUsagePercentage =>
      maxServices > 0 ? (currentServicesCount / maxServices * 100) : 0;

  double get photosUsagePercentage =>
      maxPhotos > 0 ? (currentPhotosCount / maxPhotos * 100) : 0;

  double get bookingsUsagePercentage =>
      maxBookingsPerMonth > 0 ? (currentBookingsCount / maxBookingsPerMonth * 100) : 0;

  double get employeesUsagePercentage =>
      maxEmployees > 0 ? (currentEmployeesCount / maxEmployees * 100) : 0;
}

class SubscriptionService {
  final ApiClient _apiClient;

  SubscriptionService(this._apiClient);

  Future<List<SubscriptionPlan>> getPlans() async {
    final response = await _apiClient.dio.get('/api/subscriptions/plans');
    final data = response.data as List;
    return data.map((json) => SubscriptionPlan.fromJson(json)).toList();
  }

  Future<CurrentSubscription?> getCurrentSubscription() async {
    try {
      final response = await _apiClient.dio.get('/api/subscriptions/current');
      final data = response.data;
      if (data == null || data['hasSubscription'] == false) return null;
      return CurrentSubscription.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getBookingLimitStatus() async {
    final response = await _apiClient.dio.get('/api/subscriptions/current/status');
    return response.data;
  }

  Future<void> subscribe(String planId, bool isYearly) async {
    await _apiClient.dio.post('/api/subscriptions/subscribe', data: {
      'planId': planId,
      'isYearly': isYearly,
    });
  }

  Future<void> upgrade(String newPlanId) async {
    await _apiClient.dio.post('/api/subscriptions/upgrade', data: {
      'newPlanId': newPlanId,
      'paymentMethod': 'cash',
    });
  }

  Future<void> cancel() async {
    await _apiClient.dio.post('/api/subscriptions/cancel');
  }

  Future<List<Map<String, dynamic>>> getHistory() async {
    final response = await _apiClient.dio.get('/api/subscriptions/history');
    return List<Map<String, dynamic>>.from(response.data);
  }

  Future<Map<String, dynamic>> checkFeature(String feature) async {
    final response = await _apiClient.dio.get('/api/subscriptions/check/$feature');
    return response.data;
  }
}
