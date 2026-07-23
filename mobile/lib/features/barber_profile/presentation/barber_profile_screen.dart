import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong2;
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/utils/error_extractor.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/rating_badge.dart';
import '../../home/data/barbers_service.dart';
import '../../booking_flow/presentation/booking_flow_screen.dart';
import '../../account/data/customer_service.dart';
import '../../bookings/data/bookings_service.dart';

class BarberProfileScreen extends StatefulWidget {
  final String barberId;

  const BarberProfileScreen({super.key, required this.barberId});

  @override
  State<BarberProfileScreen> createState() => _BarberProfileScreenState();
}

class _BarberProfileScreenState extends State<BarberProfileScreen> {
  final BarbersService _barberService = BarbersService(ApiClient());
  final CustomerService _customerService = CustomerService(ApiClient());
  final BookingsService _bookingsService = BookingsService(ApiClient());
  BarberDetailModel? _barberDetail;
  bool _isLoading = true;
  String? _error;
  int _selectedReviewFilter = 5;
  bool _isFavorite = false;
  List<AvailableSlotModel> _availableSlots = [];
  bool _slotsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBarberDetail();
    _checkFavorite();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _slotsLoading = true);
    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final slots = await _bookingsService.getAvailableSlots(barberProfileId: widget.barberId, date: today, scope: 'profile');
      if (mounted) setState(() { _availableSlots = slots; _slotsLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _slotsLoading = false);
    }
  }

  Future<void> _loadBarberDetail() async {
    try {
      final detail = await _barberService.getBarberById(widget.barberId);
      setState(() { _barberDetail = detail; _isLoading = false; });
      _loadAvailableSlots();
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await _customerService.checkFavorite(widget.barberId);
      setState(() => _isFavorite = isFav);
    } catch (_) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) { await _customerService.removeFavorite(widget.barberId); }
      else { await _customerService.addFavorite(widget.barberId); }
      setState(() => _isFavorite = !_isFavorite);
    } catch (e) {
      String msg = extractErrorMessage(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    }
  }

  void _proceedToBooking() {
    HapticFeedback.lightImpact();
    Get.to(() => BookingFlowScreen(barberProfileId: widget.barberId, selectedServiceIds: _barberDetail!.services.map((s) => s.id).toList()), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    if (_isLoading) {
      return Scaffold(backgroundColor: context.backgroundColor, body: const Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    if (_error != null || _barberDetail == null) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.error, size: 48),
              const SizedBox(height: 16),
              Text(_error ?? 'حدث خطأ', style: AppTextStyles.body(isDark)),
              const SizedBox(height: 16),
              AppButton(label: 'إعادة المحاولة', onPressed: _loadBarberDetail, isSmall: true, width: 160),
            ],
          ),
        ),
      );
    }

    final barber = _barberDetail!;
    final portfolioImages = barber.portfolioImages;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeroImage(barber, isDark)),
              SliverToBoxAdapter(child: _buildBarberInfo(barber, isDark)),
              if (portfolioImages.isNotEmpty) SliverToBoxAdapter(child: _buildMyWork(portfolioImages, isDark)),
              SliverToBoxAdapter(child: _buildServices(barber, isDark)),
              SliverToBoxAdapter(child: _buildTimeSlots(barber, isDark)),
              SliverToBoxAdapter(child: _buildLocation(barber, isDark)),
              SliverToBoxAdapter(child: _buildReviews(barber, isDark)),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeroImage(BarberDetailModel barber, bool isDark) {
    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.surfaceColor, context.surfaceColor],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ImageHelper.displayImage(
              imageUrl: barber.coverImageUrl,
              fit: BoxFit.cover,
              placeholder: Center(child: Icon(Icons.content_cut, size: 80, color: AppColors.primary.withValues(alpha: 0.3))),
            ),
          ),
          Positioned(
            top: 50, left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                child: Icon(Icons.arrow_back_ios_new, color: context.textColor, size: 20),
              ),
            ),
          ),
          Positioned(
            top: 50, right: 20,
            child: GestureDetector(
              onTap: _toggleFavorite,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                child: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? AppColors.error : context.textColor, size: 20),
              ),
            ),
          ),
          Positioned(
            bottom: 20, left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(barber.address.isNotEmpty ? barber.address : barber.city, style: AppTextStyles.bodySmall(isDark).copyWith(fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
          if (barber.isOpen)
            Positioned(
              bottom: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm), border: Border.all(color: AppColors.success.withValues(alpha: 0.3))),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.success)),
                    const SizedBox(width: 6),
                    const Text('متاح الآن', style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBarberInfo(BarberDetailModel barber, bool isDark) {
    return FadeIn(
      delay: const Duration(milliseconds: 150),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(barber.ownerName, style: AppTextStyles.headline(isDark)),
            const SizedBox(height: 8),
            RatingSummary(rating: barber.averageRating, reviewCount: barber.reviewCount),
            const SizedBox(height: 6),
            Text(barber.shopName, style: AppTextStyles.primary(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildMyWork(List<PortfolioImageModel> images, bool isDark) {
    return FadeIn(
      delay: const Duration(milliseconds: 200),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Text('أعمالي', style: AppTextStyles.subtitle(isDark))),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
                  clipBehavior: Clip.antiAlias,
                  child: ImageHelper.displayImage(
                    imageUrl: image.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      color: context.surfaceColor,
                      child: Icon(Icons.content_cut, color: AppColors.primary.withValues(alpha: 0.6), size: 30),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServices(BarberDetailModel barber, bool isDark) {
    return FadeIn(
      delay: const Duration(milliseconds: 250),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('الخدمات', style: AppTextStyles.subtitle(isDark))),
          ...barber.services.map((service) => _buildServiceItem(service, isDark)),
        ],
      ),
    );
  }

  Widget _buildServiceItem(ServiceModel service, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
            child: const Icon(Icons.content_cut, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('${service.durationInMinutes} دقيقة', style: AppTextStyles.caption(isDark)),
              ],
            ),
          ),
          Text('${service.price.toStringAsFixed(0)} ش', style: AppTextStyles.primary(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(BarberDetailModel barber, bool isDark) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final currentMinute = now.minute;

    List<String> timeSlots = [];
    final workingHours = barber.workingHours.where((w) => w.isOpen).toList();
    for (var wh in workingHours) {
      final open = _parseTime(wh.openTime);
      final close = _parseTime(wh.closeTime);
      for (var h = open; h < close; h++) {
        timeSlots.add('${h.toString().padLeft(2, '0')}:00');
        timeSlots.add('${h.toString().padLeft(2, '0')}:30');
      }
    }
    timeSlots = timeSlots.toSet().toList()..sort();

    if (timeSlots.isEmpty) {
      timeSlots = ['09:00', '09:30', '10:00', '10:30', '11:00', '11:30', '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30', '16:00', '16:30', '17:00', '17:30'];
    }

    final pastSlots = timeSlots.where((slot) {
      final parts = slot.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      if (h < currentHour) return true;
      if (h == currentHour && m <= currentMinute) return true;
      return false;
    }).toList();

    final futureSlots = timeSlots.where((slot) {
      final parts = slot.split(':');
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      if (h > currentHour) return true;
      if (h == currentHour && m > currentMinute) return true;
      return false;
    }).toList();

    final bookedTimes = _availableSlots.where((s) => !s.isAvailable).map((s) => s.time).toSet();

    return FadeIn(
      delay: const Duration(milliseconds: 300),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Row(
              children: [
                Text('المواعيد المتاحة', style: AppTextStyles.subtitle(isDark)),
                const SizedBox(width: 8),
                Text('اليوم', style: AppTextStyles.caption(isDark)),
              ],
            ),
          ),
          if (_slotsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(height: 52, child: Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2))),
            )
          else ...[
            if (pastSlots.isNotEmpty)
              SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: pastSlots.length,
                  itemBuilder: (context, index) {
                    final slot = pastSlots[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: context.surfaceColor.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.cardBorderColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(TimeFormatter.format(slot), style: TextStyle(color: context.hintColor, fontSize: 14, decoration: TextDecoration.lineThrough)),
                    );
                  },
                ),
              ),
            SizedBox(
              height: 52,
              child: futureSlots.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Center(child: Text('لا يوجد مواعيد متاحة اليوم', style: AppTextStyles.bodySmall(isDark))),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: futureSlots.length,
                      itemBuilder: (context, index) {
                        final slot = futureSlots[index];
                        final isBooked = bookedTimes.contains(slot);
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isBooked ? AppColors.error.withValues(alpha: 0.08) : context.surfaceColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isBooked ? AppColors.error.withValues(alpha: 0.3) : context.cardBorderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                               Text(TimeFormatter.format(slot), style: TextStyle(color: isBooked ? AppColors.error : context.textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                              if (isBooked) ...[const SizedBox(width: 6), const Icon(Icons.lock_outline, size: 14, color: AppColors.error)],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) return int.tryParse(parts[0]) ?? 17;
    return 17;
  }

  Widget _buildLocation(BarberDetailModel barber, bool isDark) {
    final hasCoordinates = barber.latitude != null && barber.longitude != null && barber.latitude != 0 && barber.longitude != 0;

    return FadeIn(
      delay: const Duration(milliseconds: 350),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('الموقع', style: AppTextStyles.subtitle(isDark))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            height: 160,
            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
            clipBehavior: Clip.antiAlias,
            child: hasCoordinates
                ? FlutterMap(
                    options: MapOptions(initialCenter: latlong2.LatLng(barber.latitude!, barber.longitude!), initialZoom: 15, interactionOptions: const InteractionOptions(flags: InteractiveFlag.none)),
                    children: [
                      TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.barberbooking.app'),
                      MarkerLayer(markers: [Marker(point: latlong2.LatLng(barber.latitude!, barber.longitude!), width: 40, height: 40, child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40))]),
                    ],
                  )
                : Stack(children: [Center(child: Icon(Icons.map_outlined, color: AppColors.primary.withValues(alpha: 0.4), size: 50))]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('${barber.address}, ${barber.city}', style: AppTextStyles.secondary(isDark))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviews(BarberDetailModel barber, bool isDark) {
    final reviewCounts = [0, 0, 0, 0, 0];
    for (var review in barber.reviews) {
      if (review.rating >= 1 && review.rating <= 5) reviewCounts[review.rating - 1]++;
    }
    final maxCount = reviewCounts.reduce((a, b) => a > b ? a : b);
    final filteredReviews = _selectedReviewFilter == 5 ? barber.reviews : barber.reviews.where((r) => r.rating == _selectedReviewFilter).toList();

    return FadeIn(
      delay: const Duration(milliseconds: 400),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 12), child: Text('التقييمات', style: AppTextStyles.subtitle(isDark))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(barber.averageRating.toStringAsFixed(1), style: TextStyle(color: context.textColor, fontSize: 40, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Row(children: List.generate(5, (i) => Icon(i < barber.averageRating.round() ? Icons.star : Icons.star_border, color: AppColors.ratingStar, size: 20))),
                    const SizedBox(height: 4),
                    Text('${barber.reviewCount} تقييم', style: AppTextStyles.caption(isDark)),
                  ],
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: List.generate(5, (i) {
                      final starNum = 5 - i;
                      final count = reviewCounts[starNum - 1];
                      final ratio = maxCount > 0 ? count / maxCount : 0.0;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            Text('$starNum', style: AppTextStyles.caption(isDark)),
                            const SizedBox(width: 6),
                            const Icon(Icons.star, color: AppColors.ratingStar, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(value: ratio, backgroundColor: context.surfaceColor, valueColor: const AlwaysStoppedAnimation<Color>(AppColors.ratingStar), minHeight: 6),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('$count', style: AppTextStyles.caption(isDark)),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: 6,
              itemBuilder: (context, index) {
                final label = index == 0 ? 'الكل' : '$index';
                final filterValue = index;
                final isActive = index == 0 ? _selectedReviewFilter == 5 : _selectedReviewFilter == filterValue;
                return GestureDetector(
                  onTap: () => setState(() => _selectedReviewFilter = index == 0 ? 5 : filterValue),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary.withValues(alpha: 0.15) : context.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.primary : context.cardBorderColor),
                    ),
                    child: Center(
                      child: Row(
                        children: [
                          if (index != 0) ...[
                            Text(label, style: TextStyle(color: isActive ? AppColors.primary : context.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 4),
                            const Icon(Icons.star, color: AppColors.ratingStar, size: 12),
                          ] else
                            Text(label, style: TextStyle(color: isActive ? AppColors.primary : context.textSecondaryColor, fontSize: 13, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ...filteredReviews.map((review) => _buildReviewCard(review, isDark)),
          if (filteredReviews.isEmpty)
            Padding(padding: const EdgeInsets.all(20), child: Center(child: Text('لا توجد تقييمات', style: AppTextStyles.secondary(isDark)))),
        ],
      ),
    );
  }

  Widget _buildReviewCard(ReviewModel review, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.customerName, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(_formatDate(review.createdAt), style: AppTextStyles.caption(isDark)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.ratingStar, size: 12),
                    const SizedBox(width: 4),
                    Text('${review.rating}', style: AppTextStyles.primary(isDark).copyWith(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review.comment, style: AppTextStyles.bodySmall(isDark)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()} شهر مضى';
    if (diff.inDays > 0) return '${diff.inDays} يوم مضى';
    if (diff.inHours > 0) return '${diff.inHours} ساعة مضت';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقيقة مضت';
    return 'الآن';
  }

  Widget _buildBottomBar(bool isDark) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor.withValues(alpha: 0.5)))),
        child: SafeArea(
          top: false,
          child: AppButton(label: 'احجز الآن', onPressed: _proceedToBooking, height: 52),
        ),
      ),
    );
  }
}
