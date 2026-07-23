class BarberRegistrationData {
  // Step 1 - Basic Info
  String fullName = '';
  String phoneNumber = '';
  String password = '';

  // Step 2 - Business Info
  String shopName = '';
  String shopDescription = '';
  String? barberPhotoPath;
  String? shopLogoPath;
  String? barberPhotoBase64;
  String? shopLogoBase64;

  // Step 3 - Location
  String city = 'بيت لحم';
  String address = '';
  double? latitude;
  double? longitude;

  // Step 4 - Services
  List<BarberService> services = [];

  // Step 5 - Working Hours
  List<DaySchedule> workingHours = [];

  // Step 6 - Plan
  String selectedPlan = 'pro';
  bool isYearly = false;

  int get totalServices => services.length;

  String get workingHoursSummary {
    final enabledDays = workingHours.where((d) => d.isEnabled).length;
    return '$enabledDays أيام';
  }
}

class BarberService {
  String name;
  String price;
  String duration;

  BarberService({
    required this.name,
    required this.price,
    required this.duration,
  });
}

class DaySchedule {
  String dayName;
  bool isEnabled;
  String startTime;
  String endTime;

  DaySchedule({
    required this.dayName,
    this.isEnabled = true,
    this.startTime = '09:00 AM',
    this.endTime = '10:00 PM',
  });
}
