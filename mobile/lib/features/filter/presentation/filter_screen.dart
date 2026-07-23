import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';

class FilterParams {
  final String? city;
  final double? maxDistance;
  final String? priceCategory;
  final double? minRating;
  final bool? availableNow;
  final bool? today;
  final bool? thisWeek;

  FilterParams({
    this.city,
    this.maxDistance,
    this.priceCategory,
    this.minRating,
    this.availableNow,
    this.today,
    this.thisWeek,
  });

  String get summary {
    final parts = <String>[];
    if (maxDistance != null && maxDistance != 5) {
      parts.add('أقل من ${maxDistance!.toInt()} كم');
    }
    if (priceCategory != null) {
      parts.add(priceCategory!);
    }
    if (minRating != null) {
      parts.add('$minRating+ نجوم');
    }
    if (availableNow == true) parts.add('متاح الآن');
    if (today == true) parts.add('اليوم');
    if (thisWeek == true) parts.add('هذا الأسبوع');
    return parts.join(' • ');
  }

  bool get hasFilters =>
      maxDistance != null ||
      priceCategory != null ||
      minRating != null ||
      availableNow == true ||
      today == true ||
      thisWeek == true;
}

class FilterScreen extends StatefulWidget {
  final FilterParams? currentFilters;

  const FilterScreen({super.key, this.currentFilters});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  double _distance = 5;
  String _selectedPrice = '';
  String _selectedRating = 'الكل';
  bool _availableNow = false;
  bool _today = false;
  bool _thisWeek = false;
  String? _selectedCity;

  @override
  void initState() {
    super.initState();
    if (widget.currentFilters != null) {
      final f = widget.currentFilters!;
      if (f.maxDistance != null) _distance = f.maxDistance!;
      if (f.priceCategory != null) _selectedPrice = f.priceCategory!;
      if (f.minRating != null) {
        if (f.minRating == 4.0) _selectedRating = '4.0+';
        if (f.minRating == 4.5) _selectedRating = '4.5+';
      }
      if (f.availableNow == true) _availableNow = true;
      if (f.today == true) _today = true;
      if (f.thisWeek == true) _thisWeek = true;
      if (f.city != null) _selectedCity = f.city;
    }
  }

  void _applyFilters() {
    final result = FilterParams(
      city: _selectedCity,
      maxDistance: _distance != 5 ? _distance : null,
      priceCategory: _selectedPrice.isNotEmpty ? _selectedPrice : null,
      minRating: _selectedRating == '4.0+'
          ? 4.0
          : _selectedRating == '4.5+'
              ? 4.5
              : null,
      availableNow: _availableNow ? true : null,
      today: _today ? true : null,
      thisWeek: _thisWeek ? true : null,
    );
    Get.back(result: result);
  }

  void _resetFilters() {
    setState(() {
      _distance = 5;
      _selectedPrice = '';
      _selectedRating = 'الكل';
      _availableNow = false;
      _today = false;
      _thisWeek = false;
      _selectedCity = null;
    });
  }

  bool get _hasActiveFilters =>
      _distance != 5 ||
      _selectedPrice.isNotEmpty ||
      _selectedRating != 'الكل' ||
      _availableNow ||
      _today ||
      _thisWeek ||
      _selectedCity != null;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
                    ),
                  ),
                  Text(
                    'فلتر البحث',
                    style: TextStyle(
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_hasActiveFilters)
                    GestureDetector(
                      onTap: _resetFilters,
                      child: const Text(
                        'إعادة تعيين',
                        style: TextStyle(color: AppColors.primary, fontSize: 14),
                      ),
                    )
                  else
                    const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FadeIn(
                      delay: const Duration(milliseconds: 100),
                      child: _buildCityFilter(),
                    ),
                    const SizedBox(height: 28),
                    FadeIn(
                      delay: const Duration(milliseconds: 200),
                      child: _buildDistanceFilter(),
                    ),
                    const SizedBox(height: 28),
                    FadeIn(
                      delay: const Duration(milliseconds: 300),
                      child: _buildPriceFilter(),
                    ),
                    const SizedBox(height: 28),
                    FadeIn(
                      delay: const Duration(milliseconds: 400),
                      child: _buildRatingFilter(),
                    ),
                    const SizedBox(height: 28),
                    FadeIn(
                      delay: const Duration(milliseconds: 500),
                      child: _buildAvailabilityFilter(),
                    ),
                  ],
                ),
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                _distance == 5 ? 'الكل' : 'أقل من ${_distance.toStringAsFixed(0)} كم',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
                const SizedBox(width: 4),
                Text(
                  'المسافة',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
            thumbColor: AppColors.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: _distance,
            min: 1,
            max: 20,
            divisions: 19,
            onChanged: (value) => setState(() => _distance = value),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('1 كم', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 11)),
            Text('20 كم', style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  Widget _buildCityFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const cities = [
      'رام الله',
      'بيت لحم',
      'نابلس',
      'الخليل',
      'جنين',
      'غزة',
      'طولكرم',
      'قلقيلية',
      'سلفيت',
      'أريحا',
      'القدس',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.location_city, color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Text(
              'المدينة',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildCityChip('الكل'),
            ...cities.map((city) => _buildCityChip(city)),
          ],
        ),
      ],
    );
  }

  Widget _buildCityChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCity == null && label == 'الكل'
        ? true
        : _selectedCity == label && label != 'الكل';
    return GestureDetector(
      onTap: () => setState(() => _selectedCity = label == 'الكل' ? null : label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'الكل') ...[
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.attach_money, color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Text(
              'فئة السعر (شيكل)',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildPriceChip(''),
            const SizedBox(width: 8),
            _buildPriceChip('اقتصادي'),
            const SizedBox(width: 8),
            _buildPriceChip('متوسطة'),
            const SizedBox(width: 8),
            _buildPriceChip('VIP'),
          ],
        ),
      ],
    );
  }

  Widget _buildPriceChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedPrice == label;
    final displayLabel = label.isEmpty ? 'الكل' : label;
    return GestureDetector(
      onTap: () => setState(() => _selectedPrice = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.star_outline, color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Text(
              'التقييم',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildRatingChip('الكل'),
            const SizedBox(width: 8),
            _buildRatingChip('4.0+'),
            const SizedBox(width: 8),
            _buildRatingChip('4.5+'),
          ],
        ),
      ],
    );
  }

  Widget _buildRatingChip(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedRating == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedRating = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != 'الكل') ...[
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityFilter() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_outlined, color: AppColors.primary, size: 18),
            const SizedBox(width: 4),
            Text(
              'التوفر',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          ),
          child: Column(
            children: [
              _buildToggleRow('متاح الآن', _availableNow, (val) {
                setState(() => _availableNow = val);
              }),
              Divider(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder, height: 24),
              _buildToggleRow('اليوم', _today, (val) {
                setState(() => _today = val);
              }),
              Divider(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder, height: 24),
              _buildToggleRow('هذا الأسبوع', _thisWeek, (val) {
                setState(() => _thisWeek = val);
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleRow(String label, bool value, Function(bool) onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
        ),
        Transform.scale(
          scale: 0.9,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
            inactiveThumbColor: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
            inactiveTrackColor: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomButtons() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder).withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _hasActiveFilters ? _resetFilters : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  side: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('إعادة تعيين'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _applyFilters,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تطبيق الفلتر',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
