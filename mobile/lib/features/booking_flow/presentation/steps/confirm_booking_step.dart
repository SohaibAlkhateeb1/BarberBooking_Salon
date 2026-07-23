import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/animations/app_animations.dart';
import '../../../../core/utils/time_formatter.dart';
import '../../../../core/utils/error_extractor.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/network/api_client.dart';
import '../../../home/data/barbers_service.dart';
import '../../../bookings/data/bookings_service.dart';
import '../booking_success_screen.dart';

class ConfirmBookingStep extends StatefulWidget {
  final BarberDetailModel barberDetail;
  final ServiceModel selectedService;
  final List<ServiceModel> selectedServices;
  final DateTime selectedDate;
  final String selectedTime;
  final String? promoCode;
  final String? notes;
  final ValueChanged<String?> onPromoCodeChanged;
  final ValueChanged<String?> onNotesChanged;
  final String barberProfileId;
  final String? employeeId;
  final String? employeeName;

  const ConfirmBookingStep({super.key, required this.barberDetail, required this.selectedService, required this.selectedServices, required this.selectedDate, required this.selectedTime, this.promoCode, this.notes, required this.onPromoCodeChanged, required this.onNotesChanged, required this.barberProfileId, this.employeeId, this.employeeName});

  @override
  State<ConfirmBookingStep> createState() => _ConfirmBookingStepState();
}

class _ConfirmBookingStepState extends State<ConfirmBookingStep> {
  final BookingsService _bookingsService = BookingsService(ApiClient());
  bool _isBooking = false;
  String? _promoCode;
  String? _notes;

  @override
  void initState() { super.initState(); _promoCode = widget.promoCode; _notes = widget.notes; }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final services = widget.selectedServices.isNotEmpty ? widget.selectedServices : [widget.selectedService];
      final serviceIds = services.map((s) => s.id).toList();
      await _bookingsService.createBooking(barberProfileId: widget.barberProfileId, barberServiceId: services.first.id, bookingDate: dateStr, bookingTime: widget.selectedTime, notes: _notes?.isNotEmpty == true ? _notes : null, promoCode: _promoCode?.isNotEmpty == true ? _promoCode : null, serviceIds: serviceIds, employeeId: widget.employeeId);
      if (mounted) {
        final totalPrice = services.fold<double>(0, (sum, s) => sum + s.price);
        final names = services.map((s) => s.name).join(' + ');
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => BookingSuccessScreen(barberName: widget.barberDetail.ownerName, serviceName: names, servicePrice: totalPrice, date: DateFormat('EEEE d MMMM', 'ar').format(widget.selectedDate), time: widget.selectedTime)));
      }
    } catch (e) {
      setState(() => _isBooking = false);
      String msg = extractErrorMessage(e);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                FadeIn(child: Text('تأكيد الحجز', style: AppTextStyles.headline(isDark))),
                const SizedBox(height: 4),
                FadeIn(delay: const Duration(milliseconds: 100), child: Text('راجع تفاصيل حجزك قبل التأكيد', style: AppTextStyles.secondary(isDark))),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 200), child: _buildSummaryCard(isDark)),
                const SizedBox(height: 16),
                FadeIn(delay: const Duration(milliseconds: 300), child: _buildMapPlaceholder(isDark)),
                const SizedBox(height: 16),
                FadeIn(delay: const Duration(milliseconds: 350), child: _buildAddressRow(isDark)),
                const SizedBox(height: 20),
                FadeIn(delay: const Duration(milliseconds: 400), child: _buildPromoCodeField(isDark)),
                const SizedBox(height: 12),
                FadeIn(delay: const Duration(milliseconds: 450), child: _buildNotesField(isDark)),
              ],
            ),
          ),
        ),
        _buildBottomButton(isDark),
      ],
    );
  }

  Widget _buildSummaryCard(bool isDark) {
    final services = widget.selectedServices.isNotEmpty ? widget.selectedServices : [widget.selectedService];
    final total = services.fold<double>(0, (sum, s) => sum + s.price);

    return AppCard(
      child: Column(
        children: [
          _buildSummaryRow(Icons.person_outline, 'الحلاق', widget.barberDetail.ownerName, isDark),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
          _buildSummaryRow(Icons.content_cut, 'الخدمة', services.length > 1 ? services.map((s) => s.name).join(' + ') : services.first.name, isDark),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
          _buildSummaryRow(Icons.calendar_today_outlined, 'التاريخ', DateFormat('EEEE d MMMM', 'ar').format(widget.selectedDate), isDark),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
          _buildSummaryRow(Icons.access_time, 'الوقت', TimeFormatter.format(widget.selectedTime), isDark),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Divider(color: context.cardBorderColor, height: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المجموع', style: AppTextStyles.secondary(isDark)),
              Text('${total.toStringAsFixed(0)} ش', style: AppTextStyles.primary(isDark).copyWith(fontWeight: FontWeight.bold, fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.caption(isDark)),
        const Spacer(),
        Flexible(
          child: Text(value, style: AppTextStyles.bodyMedium(isDark).copyWith(fontWeight: FontWeight.w500, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }

  Widget _buildMapPlaceholder(bool isDark) {
    return Container(
      height: 140,
      decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.md), border: Border.all(color: context.cardBorderColor)),
      child: Stack(
        children: [
          Center(child: Icon(Icons.map_outlined, color: AppColors.primary.withValues(alpha: 0.4), size: 50)),
          Positioned(
            top: 12, right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: context.surfaceColor, borderRadius: BorderRadius.circular(AppBorderRadius.sm)),
              child: const Icon(Icons.my_location, color: AppColors.primary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(bool isDark) {
    return Row(
      children: [
        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('${widget.barberDetail.address}, ${widget.barberDetail.city}', style: AppTextStyles.secondary(isDark))),
      ],
    );
  }

  Widget _buildPromoCodeField(bool isDark) {
    return TextField(
      onChanged: (value) { _promoCode = value; widget.onPromoCodeChanged(value); },
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'كود الخصم (اختياري)',
        prefixIcon: const Icon(Icons.local_offer_outlined, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: context.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        hintStyle: TextStyle(color: context.hintColor),
      ),
    );
  }

  Widget _buildNotesField(bool isDark) {
    return TextField(
      onChanged: (value) { _notes = value; widget.onNotesChanged(value); },
      maxLines: 3,
      style: TextStyle(color: context.textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: 'ملاحظات (اختياري)',
        prefixIcon: const Icon(Icons.note_outlined, size: 20, color: AppColors.primary),
        filled: true,
        fillColor: context.surfaceColor,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: BorderSide(color: context.cardBorderColor)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppBorderRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        hintStyle: TextStyle(color: context.hintColor),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(color: context.surfaceColor, border: Border(top: BorderSide(color: context.cardBorderColor))),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: 'تأكيد الحجز',
          isLoading: _isBooking,
          onPressed: _isBooking ? null : _confirmBooking,
        ),
      ),
    );
  }
}
