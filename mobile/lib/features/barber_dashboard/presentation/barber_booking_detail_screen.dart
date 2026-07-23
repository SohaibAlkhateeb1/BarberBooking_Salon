import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/utils/time_formatter.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/app_button.dart';
import '../data/barber_dashboard_service.dart';

class BarberBookingDetailScreen extends StatefulWidget {
  final String bookingId;
  const BarberBookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BarberBookingDetailScreen> createState() => _BarberBookingDetailScreenState();
}

class _BarberBookingDetailScreenState extends State<BarberBookingDetailScreen> {
  final BarberDashboardService _service = BarberDashboardService(ApiClient());
  BarberBookingModel? _booking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    try {
      final data = await _service.getBookingDetail(widget.bookingId);
      if (mounted) setState(() { _booking = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Upcoming': return AppColors.primary;
      case 'Completed': return AppColors.success;
      case 'Cancelled': return AppColors.error;
      default: return AppColors.primary;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'Upcoming': return 'مؤكد';
      case 'Completed': return 'مكتمل';
      case 'Cancelled': return 'ملغي';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _booking == null
                ? Center(child: Text('خطأ', style: AppTextStyles.body(context.isDark).copyWith(color: context.textSecondaryColor)))
                : SingleChildScrollView(
                    padding: AppSpacing.pageAll,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeIn(
                          delay: const Duration(milliseconds: 100),
                          child: _buildHeader(),
                        ),
                        const SizedBox(height: 20),
                        FadeIn(
                          delay: const Duration(milliseconds: 200),
                          child: _buildCustomerInfo(),
                        ),
                        const SizedBox(height: 16),
                        FadeIn(
                          delay: const Duration(milliseconds: 300),
                          child: _buildServiceInfo(),
                        ),
                        const SizedBox(height: 16),
                        FadeIn(
                          delay: const Duration(milliseconds: 350),
                          child: _buildPaymentInfo(),
                        ),
                        const SizedBox(height: 16),
                        if (_booking!.notes != null && _booking!.notes!.isNotEmpty) ...[
                          FadeIn(
                            delay: const Duration(milliseconds: 400),
                            child: _buildNotesSection(),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_booking!.status == 'Upcoming') FadeIn(
                          delay: const Duration(milliseconds: 500),
                          child: _buildActionButtons(),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: context.textColor, size: 20),
        ),
        const Spacer(),
        Text('تفاصيل الموعد', style: AppTextStyles.title(context.isDark)),
        const Spacer(),
        const SizedBox(width: 20),
      ],
    );
  }

  Widget _buildCustomerInfo() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_booking!.customerName, style: AppTextStyles.title(context.isDark)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.phone, color: context.textSecondaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(_booking!.customerPhone, style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(_booking!.status).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Text(_statusText(_booking!.status), style: TextStyle(color: _statusColor(_booking!.status), fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(_booking!.bookingDate, style: AppTextStyles.body(context.isDark)),
              const Spacer(),
              const Icon(Icons.access_time, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(TimeFormatter.format(_booking!.bookingTime), style: AppTextStyles.body(context.isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServiceInfo() {
    final b = _booking!;
    final hasDiscount = b.hasDiscount;
    final employeeAssigned = b.employeeName != null && b.employeeName!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تفاصيل الخدمة', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: const Icon(Icons.content_cut, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(b.serviceName, style: AppTextStyles.body(context.isDark).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text('${b.serviceDuration} دقيقة', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
                  ],
                ),
              ),
              if (hasDiscount)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${b.totalPrice.toStringAsFixed(0)}₪', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor, decoration: TextDecoration.lineThrough)),
                    Text('${b.effectivePrice.toStringAsFixed(0)}₪', style: AppTextStyles.title(context.isDark).copyWith(color: AppColors.primary)),
                  ],
                )
              else
                Text('${b.effectivePrice.toStringAsFixed(0)}₪', style: AppTextStyles.title(context.isDark).copyWith(color: AppColors.primary)),
            ],
          ),
          if (employeeAssigned) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.primary.withValues(alpha: 0.8), size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(b.employeeName!, style: AppTextStyles.bodySmall(context.isDark).copyWith(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ],
          if (hasDiscount) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppBorderRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_offer_outlined, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('كود الخصم: ${b.promoCode}', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Text('-${b.discountAmount!.toStringAsFixed(0)}₪', style: const TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final b = _booking!;
    String paymentStatusText;
    Color paymentStatusColor;
    switch (b.paymentStatus) {
      case 'Paid':
        paymentStatusText = 'مدفوع';
        paymentStatusColor = AppColors.success;
        break;
      case 'Unpaid':
        paymentStatusText = 'غير مدفوع';
        paymentStatusColor = AppColors.error;
        break;
      default:
        paymentStatusText = b.paymentStatus ?? 'غير محدد';
        paymentStatusColor = context.textSecondaryColor;
    }

    String paymentMethodText = '';
    if (b.paymentMethod == 'cash') {
      paymentMethodText = 'كاش';
    } else if (b.paymentMethod == 'card') {
      paymentMethodText = 'بطاقة';
    }

    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الدفع', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.payments_outlined, color: AppColors.primary.withValues(alpha: 0.7), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Flexible(child: Text('حالة الدفع:', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: paymentStatusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Text(paymentStatusText, style: TextStyle(color: paymentStatusColor, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              if (paymentMethodText.isNotEmpty) ...[
                const SizedBox(width: 12),
                Icon(Icons.money, color: AppColors.primary.withValues(alpha: 0.7), size: 16),
                const SizedBox(width: 4),
                Text(paymentMethodText, style: AppTextStyles.body(context.isDark).copyWith(fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ملاحظات العميل', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
          const SizedBox(height: 8),
          Text(_booking!.notes!, style: AppTextStyles.body(context.isDark)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: 'رفض',
            type: AppButtonType.danger,
            onPressed: () async {
              await _service.rejectBooking(_booking!.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AppButton(
            label: 'إكمال الحجز',
            type: AppButtonType.primary,
            onPressed: () async {
              await _service.completeBooking(_booking!.id);
              if (mounted) Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }
}
