import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/error_extractor.dart';

class EmployeeServicesScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;

  const EmployeeServicesScreen({
    super.key,
    required this.employeeId,
    required this.employeeName,
  });

  @override
  State<EmployeeServicesScreen> createState() => _EmployeeServicesScreenState();
}

class _EmployeeServicesScreenState extends State<EmployeeServicesScreen> {
  final ApiClient _api = ApiClient();
  List<_ServiceItem> _services = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    try {
      final response = await _api.dio.get(
        '/api/barber/dashboard/employees/${widget.employeeId}/services',
      );
      final data = response.data;
      final List<dynamic> servicesList = data['allServices'] ?? [];

      if (mounted) {
        setState(() {
          _services = servicesList.map((s) => _ServiceItem(
            id: s['serviceId'] ?? '',
            name: s['serviceName'] ?? '',
            price: (s['price'] ?? 0).toDouble(),
            durationMinutes: s['durationMinutes'] ?? 0,
            isAssigned: s['isAssigned'] ?? false,
          )).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveServices() async {
    setState(() => _isSaving = true);
    try {
      final assignedIds = _services
          .where((s) => s.isAssigned)
          .map((s) => s.id)
          .toList();
      await _api.dio.put(
        '/api/barber/dashboard/employees/${widget.employeeId}/services',
        data: {'serviceIds': assignedIds},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث خدمات الموظف بنجاح')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        final msg = _extractError(e);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _extractError(dynamic e) {
    return extractErrorMessage(e);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final assignedCount = _services.where((s) => s.isAssigned).length;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'خدمات ${widget.employeeName}',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _services.isEmpty
              ? _buildEmptyState(isDark)
              : Column(
                  children: [
                    _buildHeader(isDark, assignedCount),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _services.length,
                        itemBuilder: (context, index) {
                          return _buildServiceCard(isDark, _services[index], index);
                        },
                      ),
                    ),
                  ],
                ),
      bottomNavigationBar: _services.isNotEmpty
          ? _buildSaveButton(isDark)
          : null,
    );
  }

  Widget _buildHeader(bool isDark, int assignedCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.content_cut, color: AppColors.primary, size: 36),
          const SizedBox(height: 8),
          Text(
            '$assignedCount / ${_services.length}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'خدمة مُعيّنة',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(bool isDark, _ServiceItem service, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: service.isAssigned
              ? AppColors.primary.withValues(alpha: 0.5)
              : isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          width: service.isAssigned ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: service.isAssigned
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : (isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.content_cut,
              size: 18,
              color: service.isAssigned
                  ? AppColors.primary
                  : (isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.name,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${service.price.toStringAsFixed(0)}₪ • ${service.durationMinutes} دقيقة',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 1.2,
            child: Switch(
              value: service.isAssigned,
              onChanged: (val) {
                setState(() => service.isAssigned = val);
              },
              activeColor: AppColors.primary,
              activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
              inactiveTrackColor: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.content_cut,
            color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint).withValues(alpha: 0.5),
            size: 80,
          ),
          const SizedBox(height: 20),
          Text(
            'لا توجد خدمات',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف خدمات في إدارة الصالون أولاً',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        border: Border(top: BorderSide(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveServices,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('حفظ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}

class _ServiceItem {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  bool isAssigned;

  _ServiceItem({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    required this.isAssigned,
  });
}
