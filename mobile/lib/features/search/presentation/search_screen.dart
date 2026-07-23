import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';
import '../../home/data/barbers_service.dart';
import '../../filter/presentation/filter_screen.dart';
import '../../barber_profile/presentation/barber_profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final BarbersService _barbersService = BarbersService(ApiClient());

  bool _isGridView = false;
  bool _isLoading = false;
  bool _isInitialLoad = true;
  String? _error;

  List<BarberModel> _filteredBarbers = [];
  String _searchQuery = '';

  FilterParams? _activeFilters;

  @override
  void initState() {
    super.initState();
    _loadBarbers();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadBarbers({String? search, FilterParams? filters}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _barbersService.getAllBarbers(
        search: search,
        city: filters?.city,
        minRating: filters?.minRating,
        priceCategory: filters?.priceCategory,
      );
      setState(() {
        _filteredBarbers = results;
        _isLoading = false;
        _isInitialLoad = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ أثناء تحميل البيانات';
        _isLoading = false;
        _isInitialLoad = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _debounceSearch(value);
  }

  void _debounceSearch(String value) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchQuery == value) {
        if (value.isEmpty) {
          _loadBarbers();
        } else {
          _loadBarbers(search: value);
        }
      }
    });
  }

  void _onSearchSubmitted(String value) {
    _focusNode.unfocus();
    if (value.isEmpty) {
      _loadBarbers();
    } else {
      _loadBarbers(search: value);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _loadBarbers();
    _focusNode.requestFocus();
  }

  void _openFilter() async {
    final result = await Get.to<FilterParams>(
      () => FilterScreen(currentFilters: _activeFilters),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
    if (result != null) {
      setState(() {
        _activeFilters = result;
      });
      _loadBarbers(search: _searchQuery.isNotEmpty ? _searchQuery : null, filters: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(isDark),
            if (_activeFilters != null) _buildActiveFilters(isDark),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState(isDark)
                  : _error != null
                      ? _buildErrorState(isDark)
                      : _buildResultsSection(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(bool isDark) {
    return _isGridView
        ? GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
            ),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonCard(),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: 6,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Get.back(),
              child: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
            ),
            const SizedBox(width: 10),
            Icon(Icons.search, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
                onChanged: _onSearchChanged,
                onSubmitted: _onSearchSubmitted,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'ابحث عن حلاق، خدمة...',
                  hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 15),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: _clearSearch,
                          child: Icon(Icons.close, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 20),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: _openFilter,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _activeFilters != null
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.tune,
                  color: _activeFilters != null ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.filter_list, color: AppColors.primary, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              _activeFilters!.summary,
              style: const TextStyle(color: AppColors.primary, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() {
                _activeFilters = null;
              });
              _loadBarbers(search: _searchQuery.isNotEmpty ? _searchQuery : null);
            },
            child: const Text(
              'إزالة الفلتر',
              style: TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return FadeIn(
      child: ErrorState(
        message: _error,
        onRetry: () => _loadBarbers(
          search: _searchQuery.isNotEmpty ? _searchQuery : null,
          filters: _activeFilters,
        ),
      ),
    );
  }

  Widget _buildResultsSection(bool isDark) {
    if (_isInitialLoad) {
      return _buildLoadingState(isDark);
    }

    if (_filteredBarbers.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return Column(
      children: [
        _buildResultsHeader(isDark),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadBarbers(
              search: _searchQuery.isNotEmpty ? _searchQuery : null,
              filters: _activeFilters,
            ),
            color: AppColors.primary,
            child: _isGridView ? _buildGridView(isDark) : _buildListView(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeIn(
      child: EmptyState(
        type: _searchQuery.isNotEmpty ? EmptyStateType.search : EmptyStateType.services,
        title: _searchQuery.isNotEmpty
            ? 'لا توجد نتائج لـ "$_searchQuery"'
            : 'لم يتم العثور على حلاقين',
        subtitle: _searchQuery.isNotEmpty
            ? 'جرّب كلمات بحث مختلفة\nأو غيّر معايير البحث'
            : 'لم يتم العثور على حلاقين',
        actionLabel: _searchQuery.isNotEmpty ? 'مسح البحث' : null,
        onAction: _searchQuery.isNotEmpty ? _clearSearch : null,
      ),
    );
  }

  Widget _buildResultsHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Text(
            _searchQuery.isNotEmpty
                ? 'نتائج البحث (${_filteredBarbers.length})'
                : 'جميع الحلاقين (${_filteredBarbers.length})',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.view_list,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                  isDark: isDark,
                ),
                _buildToggleButton(
                  icon: Icons.grid_view,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _filteredBarbers.length,
      itemBuilder: (context, index) {
        return FadeIn(
          delay: Duration(milliseconds: index * 50),
          child: _buildListCard(_filteredBarbers[index], isDark),
        );
      },
    );
  }

  Widget _buildGridView(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: _filteredBarbers.length,
      itemBuilder: (context, index) {
        return FadeIn(
          delay: Duration(milliseconds: index * 50),
          child: _buildGridCard(_filteredBarbers[index], isDark),
        );
      },
    );
  }

  String _getServicesText(BarberModel barber) {
    if (barber.services.isEmpty) return '';
    final names = barber.services.map((s) => s.name).join('، ');
    return names;
  }

  String _getMinPrice(BarberModel barber) {
    if (barber.services.isEmpty) return '';
    final minPrice = barber.services.map((s) => s.price).reduce((a, b) => a < b ? a : b);
    return 'من ${minPrice.toInt()} شيكل';
  }

  void _navigateToProfile(BarberModel barber) {
    Get.to(
      () => BarberProfileScreen(barberId: barber.id),
      transition: Transition.rightToLeft,
      duration: const Duration(milliseconds: 250),
    );
  }

  Widget _buildGradientPlaceholder({double? width, double? height, double? iconSize}) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        gradient: AppColors.cardGlow,
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.content_cut,
          color: Colors.white.withValues(alpha: 0.8),
          size: iconSize ?? 30,
        ),
      ),
    );
  }

  Widget _buildListCard(BarberModel barber, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToProfile(barber),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageHelper.displayImage(
                imageUrl: barber.shopLogoUrl ?? barber.coverImageUrl,
                width: 80,
                height: 80,
                borderRadius: BorderRadius.circular(12),
                placeholder: _buildGradientPlaceholder(width: 80, height: 80, iconSize: 30),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          barber.shopName,
                          style: TextStyle(
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: RatingBadge(
                          rating: barber.averageRating,
                          reviewCount: barber.reviewCount,
                          showReviewCount: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: barber.isOpen ? AppColors.success : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        barber.isOpen ? 'متاح الآن' : 'مغلق',
                        style: TextStyle(
                          color: barber.isOpen ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (barber.address.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${barber.address}, ${barber.city}',
                            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      if (_getMinPrice(barber).isNotEmpty) ...[
                        Text(
                          _getMinPrice(barber),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (_getServicesText(barber).isNotEmpty)
                        Expanded(
                          child: Text(
                            _getServicesText(barber),
                            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  Widget _buildGridCard(BarberModel barber, bool isDark) {
    return GestureDetector(
      onTap: () => _navigateToProfile(barber),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: ImageHelper.displayImage(
                      imageUrl: barber.shopLogoUrl ?? barber.coverImageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: _buildGradientPlaceholder(
                        width: double.infinity,
                        height: double.infinity,
                        iconSize: 36,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isDark ? AppColors.darkSurface : AppColors.lightSurface).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: RatingBadge(
                        rating: barber.averageRating,
                        reviewCount: barber.reviewCount,
                        starSize: 12,
                        fontSize: 11,
                        showReviewCount: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      barber.shopName,
                      style: TextStyle(
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: barber.isOpen ? AppColors.success : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            barber.isOpen ? 'متاح الآن' : 'مغلق',
                            style: TextStyle(
                              color: barber.isOpen ? AppColors.success : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      _getMinPrice(barber),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
