import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';
import '../data/barber_dashboard_service.dart';

class BarberServicesScreen extends StatefulWidget {
  const BarberServicesScreen({super.key});

  @override
  State<BarberServicesScreen> createState() => _BarberServicesScreenState();
}

class _BarberServicesScreenState extends State<BarberServicesScreen> {
  final BarberDashboardService _service = BarberDashboardService(ApiClient());
  List<BarberServiceModel> _services = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _maxServices = -1;

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final api = ApiClient();
      final response = await api.dio.get('/api/subscriptions/current');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _maxServices = data['maxServices'] ?? -1;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadServices() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final data = await _service.getServices();
      if (mounted) setState(() { _services = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  void _showAddServiceSheet() {
    if (_maxServices > 0 && _services.length >= _maxServices) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppBorderRadius.lg)),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('تم الوصول للحد الأقصى', style: AppTextStyles.title(ctx.isDark)),
            ],
          ),
          content: Text(
            'لقد وصلت للحد الأقصى من الخدمات ($_maxServices خدمة). قم بالترقية لخطة أعلى لإضافة المزيد.',
            style: AppTextStyles.body(ctx.isDark).copyWith(color: ctx.textSecondaryColor),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('حسناً', style: AppTextStyles.primary(ctx.isDark))),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceFormSheet(
        onSave: (name, price, duration) async {
          await _service.addService(name: name, price: price, duration: duration);
          _loadServices();
        },
      ),
    );
  }

  void _showEditServiceSheet(BarberServiceModel service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ServiceFormSheet(
        initialName: service.name,
        initialPrice: service.price,
        initialDuration: service.durationInMinutes,
        onSave: (name, price, duration) async {
          await _service.updateService(service.id, name: name, price: price, duration: duration);
          _loadServices();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('خدماتي', style: AppTextStyles.headline(context.isDark)),
                  GestureDetector(
                    onTap: _showAddServiceSheet,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                      ),
                      child: Icon(Icons.add, color: context.backgroundColor, size: 22),
                    ),
                  ),
                ],
              ),
            ),
            if (_maxServices > 0)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _services.length >= _maxServices
                      ? AppColors.error.withValues(alpha: 0.1)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppBorderRadius.sm),
                ),
                child: Row(
                  children: [
                    Icon(
                      _services.length >= _maxServices ? Icons.warning_amber : Icons.content_cut,
                      color: _services.length >= _maxServices ? AppColors.error : AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_services.length} / $_maxServices خدمة',
                      style: TextStyle(
                        color: _services.length >= _maxServices ? AppColors.error : AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? _buildSkeletonLoader()
                  : _hasError
                      ? ErrorState(onRetry: _loadServices)
                      : _services.isEmpty
                          ? EmptyState(
                              type: EmptyStateType.services,
                              onAction: _showAddServiceSheet,
                            )
                          : RefreshIndicator(
                              onRefresh: _loadServices,
                              color: AppColors.primary,
                              child: ListView.builder(
                                padding: AppSpacing.pageAll,
                                itemCount: _services.length,
                                itemBuilder: (context, index) => FadeIn(
                                  delay: Duration(milliseconds: index * 50),
                                  child: _buildServiceCard(_services[index]),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonLoader() {
    return Padding(
      padding: AppSpacing.pageAll,
      child: Column(
        children: List.generate(4, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 80, borderRadius: AppBorderRadius.lg),
        )),
      ),
    );
  }

  Widget _buildServiceCard(BarberServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(AppBorderRadius.lg),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppBorderRadius.md),
            ),
            child: const Icon(Icons.content_cut, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service.name, style: AppTextStyles.body(context.isDark).copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('${service.durationInMinutes} دقيقة', style: AppTextStyles.bodySmall(context.isDark).copyWith(color: context.textSecondaryColor)),
              ],
            ),
          ),
          Text('${service.price.toStringAsFixed(0)} ش', style: AppTextStyles.primary(context.isDark).copyWith(fontSize: 16)),
          const SizedBox(width: 12),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: context.hintColor),
            color: context.surfaceColor,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, color: AppColors.primary, size: 18), const SizedBox(width: 8), const Text('تعديل')])),
              PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: AppColors.error, size: 18), const SizedBox(width: 8), Text('حذف', style: TextStyle(color: AppColors.error))])),
            ],
            onSelected: (value) async {
              if (value == 'edit') {
                _showEditServiceSheet(service);
              } else if (value == 'delete') {
                await _service.deleteService(service.id);
                _loadServices();
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ServiceFormSheet extends StatefulWidget {
  final String? initialName;
  final double? initialPrice;
  final int? initialDuration;
  final Future<void> Function(String name, double price, int duration) onSave;

  const _ServiceFormSheet({this.initialName, this.initialPrice, this.initialDuration, required this.onSave});

  @override
  State<_ServiceFormSheet> createState() => _ServiceFormSheetState();
}

class _ServiceFormSheetState extends State<_ServiceFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _durationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _priceController = TextEditingController(text: widget.initialPrice?.toStringAsFixed(0) ?? '');
    _durationController = TextEditingController(text: widget.initialDuration?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cardBorderColor, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text(widget.initialName != null ? 'تعديل الخدمة' : 'إضافة خدمة جديدة', style: AppTextStyles.title(context.isDark)),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              style: AppTextStyles.body(context.isDark),
              decoration: InputDecoration(hintText: 'اسم الخدمة', hintStyle: AppTextStyles.hint(context.isDark)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body(context.isDark),
                    decoration: InputDecoration(hintText: 'السعر (شيكل)', hintStyle: AppTextStyles.hint(context.isDark)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    style: AppTextStyles.body(context.isDark),
                    decoration: InputDecoration(hintText: 'المدة (5 - 480 دقيقة)', hintStyle: AppTextStyles.hint(context.isDark)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'حفظ',
              isLoading: _isSaving,
              onPressed: () async {
                if (_nameController.text.isEmpty || _priceController.text.isEmpty || _durationController.text.isEmpty) return;
                final duration = int.tryParse(_durationController.text);
                if (duration == null || duration < 5 || duration > 480) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('المدة يجب أن تكون بين 5 و 480 دقيقة'), backgroundColor: AppColors.error),
                    );
                  }
                  return;
                }
                setState(() => _isSaving = true);
                await widget.onSave(
                  _nameController.text,
                  double.parse(_priceController.text),
                  duration,
                );
                if (mounted && context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
