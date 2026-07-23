import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/models/barber_registration_data.dart';
import '../../../../core/widgets/app_button.dart';

class LocationStep extends StatefulWidget {
  final BarberRegistrationData data;
  final VoidCallback onNext;
  final VoidCallback onBack;
  const LocationStep({super.key, required this.data, required this.onNext, required this.onBack});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;
  String? _locationError;

  static const Map<String, latlong.LatLng> _cityCoordinates = {
    'بيت لحم': latlong.LatLng(31.7054, 35.2024),
    'القدس': latlong.LatLng(31.7683, 35.2137),
    'نابلس': latlong.LatLng(32.2211, 35.2544),
    'الخليل': latlong.LatLng(31.5326, 35.0978),
    'رام الله': latlong.LatLng(31.8996, 35.2042),
    'طولكرم': latlong.LatLng(32.3131, 35.0289),
    'جنين': latlong.LatLng(32.4580, 35.2667),
    'قلقيلية': latlong.LatLng(31.8689, 35.0081),
    'سلفيت': latlong.LatLng(32.0833, 35.1833),
    'أريحا': latlong.LatLng(31.8720, 35.4444),
    'غزة': latlong.LatLng(31.5017, 34.4668),
    'خان يونس': latlong.LatLng(31.3402, 34.3044),
    'رفح': latlong.LatLng(31.2875, 34.2433),
    'دير البلح': latlong.LatLng(31.4183, 34.3517),
    'جباليا': latlong.LatLng(31.5375, 34.4833),
    'بئر السبع': latlong.LatLng(31.2530, 34.7919),
  };

  final List<String> _cities = [
    'بيت لحم', 'القدس', 'نابلس', 'الخليل', 'رام الله', 'طولكرم',
    'جنين', 'قلقيلية', 'سلفيت', 'أريحا', 'غزة', 'خان يونس',
    'رفح', 'دير البلح', 'جباليا', 'بئر السبع',
  ];

  latlong.LatLng _currentPosition = const latlong.LatLng(31.7054, 35.2024);
  late final TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _addressController = TextEditingController(text: widget.data.address);
    if (widget.data.latitude != null && widget.data.longitude != null) {
      _currentPosition = latlong.LatLng(widget.data.latitude!, widget.data.longitude!);
    } else if (_cityCoordinates.containsKey(widget.data.city)) {
      _currentPosition = _cityCoordinates[widget.data.city]!;
      widget.data.latitude = _currentPosition.latitude;
      widget.data.longitude = _currentPosition.longitude;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _validateAndNext() {
    if (widget.data.latitude == null || widget.data.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يجب تحديد الموقع على الخريطة', textAlign: TextAlign.center),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    if (widget.data.address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('العنوان التفصيلي مطلوب', textAlign: TextAlign.center),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    widget.onNext();
  }

  void _onMapTap(latlong.LatLng position) {
    setState(() {
      _currentPosition = position;
      widget.data.latitude = position.latitude;
      widget.data.longitude = position.longitude;
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() { _isLoadingLocation = true; _locationError = null; });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() { _locationError = 'خدمة الموقع معطّلة. فعّلها من إعدادات الجهاز.'; _isLoadingLocation = false; });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _locationError = 'تم رفض صلاحية الموقع.'; _isLoadingLocation = false; });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() { _locationError = 'صلاحية الموقع مرفوضة نهائياً. افتح إعدادات الجهاز وافتحها.'; _isLoadingLocation = false; });
        return;
      }

      final position = await Geolocator.getCurrentPosition(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high));
      final newPos = latlong.LatLng(position.latitude, position.longitude);
      widget.data.latitude = position.latitude;
      widget.data.longitude = position.longitude;
      setState(() { _currentPosition = newPos; _isLoadingLocation = false; });
      _mapController.move(newPos, 15);
    } catch (e) {
      setState(() { _locationError = 'حدث خطأ أثناء تحديد الموقع.'; _isLoadingLocation = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 0),
            child: Text('تحديد موقع الصالون', style: AppTextStyles.headline(isDark)),
          ),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 50),
            child: Text('حدد موقع صالونك بال GPS أو اضغط على الخريطة.', style: AppTextStyles.secondary(isDark)),
          ),
          const SizedBox(height: 20),
          FadeIn(
            delay: const Duration(milliseconds: 100),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.lg),
              child: Container(
                width: double.infinity,
                height: 280,
                decoration: BoxDecoration(border: Border.all(color: context.cardBorderColor)),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: _currentPosition, initialZoom: 13, onTap: (tapPosition, latLng) => _onMapTap(latLng)),
                  children: [
                    TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.barberbooking.app'),
                    MarkerLayer(markers: [Marker(point: _currentPosition, width: 40, height: 40, child: const Icon(Icons.location_pin, color: AppColors.primary, size: 40))]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FadeIn(
            delay: const Duration(milliseconds: 150),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                    icon: _isLoadingLocation
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.my_location, size: 18),
                    label: Text(_isLoadingLocation ? 'جاري التحديد...' : 'تحديد موقعي'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildMapButton(Icons.zoom_in, isDark, () { final cam = _mapController.camera; _mapController.move(cam.center, cam.zoom + 1); }),
                const SizedBox(width: 4),
                _buildMapButton(Icons.zoom_out, isDark, () { final cam = _mapController.camera; _mapController.move(cam.center, cam.zoom - 1); }),
              ],
            ),
          ),
          if (_locationError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: Text(_locationError!, style: AppTextStyles.error(isDark), textAlign: TextAlign.center),
            ),
          ],
          if (widget.data.latitude != null && widget.data.longitude != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: Text('📍 ${widget.data.latitude!.toStringAsFixed(4)}, ${widget.data.longitude!.toStringAsFixed(4)}', style: AppTextStyles.primary(isDark), textAlign: TextAlign.center),
            ),
          ],
          const SizedBox(height: 20),
          FadeIn(delay: const Duration(milliseconds: 200), child: Text('المدينة', style: AppTextStyles.secondary(isDark))),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 250),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
                border: Border.all(color: context.cardBorderColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _cities.contains(widget.data.city) ? widget.data.city : _cities[0],
                  isExpanded: true,
                  dropdownColor: context.surfaceColor,
                  icon: Icon(Icons.keyboard_arrow_down, color: context.hintColor),
                  style: TextStyle(color: context.textColor, fontSize: 15),
                  items: _cities.map((city) => DropdownMenuItem(value: city, child: Text(city))).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        widget.data.city = value;
                        final cityLoc = _cityCoordinates[value];
                        if (cityLoc != null) {
                          _currentPosition = cityLoc;
                          widget.data.latitude = cityLoc.latitude;
                          widget.data.longitude = cityLoc.longitude;
                          _mapController.move(cityLoc, 13);
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeIn(delay: const Duration(milliseconds: 300), child: Text('العنوان التفصيلي (الشارع، الحي، المعلم)', style: AppTextStyles.secondary(isDark))),
          const SizedBox(height: 8),
          FadeIn(
            delay: const Duration(milliseconds: 350),
            child: TextField(
              controller: _addressController,
              onChanged: (v) => widget.data.address = v,
              style: TextStyle(color: context.textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'مثال: شارع المهد، بيت لحم',
                prefixIcon: const Icon(Icons.home_outlined, size: 20, color: AppColors.primary),
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          FadeIn(
            delay: const Duration(milliseconds: 400),
            child: AppButton(label: 'الحفظ والمتابعة', onPressed: _validateAndNext),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMapButton(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.sm), border: Border.all(color: context.cardBorderColor)),
        child: Icon(icon, color: context.textColor, size: 22),
      ),
    );
  }
}
