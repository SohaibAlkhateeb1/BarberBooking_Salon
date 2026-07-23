class Barber {
  final String id;
  final String name;
  final String? imageUrl;
  final double rating;
  final int reviewCount;
  final double distanceKm;
  final String? specialties;
  final String? openTime;
  final String? closeTime;
  final bool isOpen;
  final double? priceFrom;
  final bool isFavorite;

  Barber({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.rating,
    this.reviewCount = 0,
    required this.distanceKm,
    this.specialties,
    this.openTime,
    this.closeTime,
    this.isOpen = false,
    this.priceFrom,
    this.isFavorite = false,
  });

  String get distance => '${distanceKm.toStringAsFixed(1)} كم';

  String get ratingText => rating.toStringAsFixed(1);

  String get openStatusText {
    if (isOpen) return 'متاح الآن';
    if (openTime != null && closeTime != null) return 'يغلق - من $openTime';
    return 'غير متاح';
  }

  factory Barber.fromJson(Map<String, dynamic> json) {
    return Barber(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'],
      rating: (json['rating'] ?? 0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      distanceKm: (json['distanceKm'] ?? 0).toDouble(),
      specialties: json['specialties'],
      openTime: json['openTime'],
      closeTime: json['closeTime'],
      isOpen: json['isOpen'] ?? false,
      priceFrom: json['priceFrom']?.toDouble(),
      isFavorite: json['isFavorite'] ?? false,
    );
  }
}
