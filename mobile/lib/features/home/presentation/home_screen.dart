import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/services/location_service.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';
import '../../home/data/barbers_service.dart';
import '../../account/data/customer_service.dart';
import '../../search/presentation/search_screen.dart';
import '../../barber_profile/presentation/barber_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BarbersService _barbersService = BarbersService(ApiClient());
  final TokenStorage _tokenStorage = TokenStorage();
  final LocationService _locationService = LocationService();
  List<BarberModel> _allBarbers = [];
  List<BarberModel> _nearbyBarbers = [];
  bool _isLoading = true;
  String _fullName = '';
  String _city = '';
  bool _hasLocation = false;
  String? _profileImageUrl;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final fullName = await _tokenStorage.getFullName();
      final city = await _tokenStorage.getCity();
      final lat = await _tokenStorage.getLatitude();
      final lng = await _tokenStorage.getLongitude();

      if (lat != null && lng != null) {
        setState(() => _hasLocation = true);
      }

      String? imageUrl;
      try {
        final customerService = CustomerService(ApiClient());
        final profile = await customerService.getProfile();
        imageUrl = profile.profileImageUrl;
      } catch (_) {}

      List<BarberModel> barbers;
      if (lat != null && lng != null) {
        try {
          barbers = await _barbersService.getNearbyBarbers(latitude: lat, longitude: lng, radiusKm: 50);
        } catch (_) {
          barbers = await _barbersService.getAllBarbers();
        }
      } else {
        barbers = await _barbersService.getAllBarbers();
      }

      if (mounted) {
        setState(() {
          _allBarbers = barbers;
          _nearbyBarbers = barbers;
          _fullName = fullName ?? '';
          _city = city ?? '';
          _profileImageUrl = imageUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await _locationService.getCurrentLocation();
    if (position != null) {
      setState(() => _hasLocation = true);
      await _loadData();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لم يتم الحصول على الموقع. تأكد من تفعيل خدمات الموقع.'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  String _formatDistance(BarberModel barber) {
    if (barber.address.isNotEmpty) return barber.address;
    if (barber.city.isNotEmpty) return barber.city;
    return '';
  }

  String _statusText(BarberModel barber) => barber.isOpen ? 'متاح الآن' : 'مشغول حالياً';
  Color _statusColor(BarberModel barber) => barber.isOpen ? AppColors.success : AppColors.error;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingSkeleton()
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppColors.primary,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      _buildSearchBar(isDark),
                      _buildFeaturedSection(isDark),
                      _buildNearbySection(isDark),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: Row(
              children: [
                const SkeletonLoader(width: 50, height: 50, borderRadius: 25),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SkeletonLoader(width: 140, height: 16, borderRadius: 8),
                  const SizedBox(height: 8),
                  SkeletonLoader(width: 100, height: 12, borderRadius: 6),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const SkeletonLoader(width: double.infinity, height: 50, borderRadius: 12),
          const SizedBox(height: 24),
          ...List.generate(3, (_) => const SkeletonCard()),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 100),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Row(
          children: [
            _buildHeaderAvatar(isDark),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('مرحباً، ${_fullName.isNotEmpty ? _fullName : 'زائر'}', style: AppTextStyles.title(isDark)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _hasLocation ? null : _getCurrentLocation,
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: _hasLocation ? AppColors.primary : AppColors.error, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _hasLocation ? (_city.isNotEmpty ? _city : 'فلسطين') : 'افتح الموقع',
                          style: TextStyle(color: _hasLocation ? context.textSecondaryColor : AppColors.error, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!_hasLocation)
              GestureDetector(
                onTap: _getCurrentLocation,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                  child: const Icon(Icons.my_location, color: AppColors.primary, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderAvatar(bool isDark) {
    return ImageHelper.displayImage(
      imageUrl: _profileImageUrl,
      width: 50,
      height: 50,
      borderRadius: BorderRadius.circular(25),
      placeholder: Container(
        width: 50, height: 50,
        decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
        child: Icon(Icons.person, color: context.backgroundColor, size: 26),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return FadeSlideIn(
      delay: const Duration(milliseconds: 200),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); Get.to(() => const SearchScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)); },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
            child: Row(
              children: [
                Icon(Icons.search, color: context.hintColor, size: 22),
                const SizedBox(width: 12),
                Expanded(child: Text('ابحث عن حلاق أو خدمة...', style: AppTextStyles.bodyMedium(isDark))),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                  child: const Icon(Icons.tune, color: AppColors.primary, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('حلقون مميزون', style: AppTextStyles.subtitle(isDark)),
              TextButton(
                onPressed: () => Get.to(() => const SearchScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                child: Text('عرض الكل', style: AppTextStyles.primary(isDark)),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: _allBarbers.isEmpty
              ? EmptyState(type: EmptyStateType.services, title: 'لا يوجد حلاقون حالياً', subtitle: 'سيظهر هنا أقرب الحلاقين إليك')
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _allBarbers.length,
                  itemBuilder: (context, index) => FadeIn(delay: Duration(milliseconds: 100 + index * 80), child: _buildFeaturedCard(_allBarbers[index], isDark)),
                ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(BarberModel barber, bool isDark) {
    return PressEffect(
      onTap: () { HapticFeedback.lightImpact(); Get.to(() => BarberProfileScreen(barberId: barber.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)); },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.lg), border: Border.all(color: context.cardBorderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 110,
              decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
              child: Stack(
                children: [
                  ImageHelper.displayImage(
                    imageUrl: barber.coverImageUrl ?? barber.shopLogoUrl,
                    width: double.infinity,
                    height: 110,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    placeholder: Container(
                      width: double.infinity,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        gradient: LinearGradient(
                          colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primaryDark.withValues(alpha: 0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(child: Icon(Icons.content_cut, size: 40, color: AppColors.primary)),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: context.surfaceColor.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                      child: RatingBadge(rating: barber.averageRating, reviewCount: barber.reviewCount, starSize: 14, fontSize: 12, showReviewCount: false),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(barber.shopName, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.content_cut, color: context.hintColor, size: 14),
                      const SizedBox(width: 4),
                      Text('${barber.services.length} خدمات', style: AppTextStyles.caption(isDark)),
                      const Spacer(),
                      if (_formatDistance(barber).isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, color: context.hintColor, size: 14),
                        const SizedBox(width: 4),
                        Flexible(child: Text(_formatDistance(barber), style: AppTextStyles.caption(isDark), overflow: TextOverflow.ellipsis)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: () => Get.to(() => BarberProfileScreen(barberId: barber.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: context.backgroundColor,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                      ),
                      child: const Text('احجز الآن', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_hasLocation ? 'بالقرب منك' : 'جميع الحلاقين', style: AppTextStyles.subtitle(isDark)),
                TextButton(
                  onPressed: () => Get.to(() => const SearchScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
                  child: Text('عرض الكل', style: AppTextStyles.primary(isDark)),
                ),
              ],
            ),
          ),
        ),
        if (_nearbyBarbers.isEmpty)
          EmptyState(
            type: EmptyStateType.search,
            title: 'لا يوجد حلاقون بالقرب منك',
            subtitle: 'جرّب توسيع نطاق البحث أو تفعيل خدمات الموقع',
            actionLabel: 'بحث',
            onAction: () => Get.to(() => const SearchScreen(), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)),
          )
        else
          ...List.generate(_nearbyBarbers.length, (index) => FadeSlideIn(
            delay: Duration(milliseconds: 350 + index * 80),
            child: _buildNearbyCard(_nearbyBarbers[index], isDark),
          )),
      ],
    );
  }

  Widget _buildNearbyCard(BarberModel barber, bool isDark) {
    return PressEffect(
      onTap: () { HapticFeedback.lightImpact(); Get.to(() => BarberProfileScreen(barberId: barber.id), transition: Transition.rightToLeft, duration: const Duration(milliseconds: 250)); },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.lg), border: Border.all(color: context.cardBorderColor)),
        child: Row(
          children: [
            ImageHelper.displayImage(
              imageUrl: barber.shopLogoUrl,
              width: 70,
              height: 70,
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
              placeholder: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppBorderRadius.md),
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.3), AppColors.primaryDark.withValues(alpha: 0.1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(Icons.content_cut, color: AppColors.primary, size: 28),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(barber.shopName, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.bold))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
                        child: RatingBadge(rating: barber.averageRating, reviewCount: barber.reviewCount, starSize: 12, fontSize: 12, showReviewCount: false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (_formatDistance(barber).isNotEmpty) ...[
                        Icon(Icons.location_on_outlined, color: context.hintColor, size: 14),
                        const SizedBox(width: 4),
                        Flexible(child: Text(_formatDistance(barber), style: AppTextStyles.bodySmall(isDark), overflow: TextOverflow.ellipsis)),
                        const SizedBox(width: 16),
                      ],
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: _statusColor(barber))),
                      const SizedBox(width: 6),
                      Text(_statusText(barber), style: TextStyle(color: _statusColor(barber), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text('${barber.services.length} خدمات', style: AppTextStyles.caption(isDark)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppBorderRadius.sm), border: Border.all(color: context.cardBorderColor)),
                        child: Text('عرض الملف', style: AppTextStyles.caption(isDark)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
