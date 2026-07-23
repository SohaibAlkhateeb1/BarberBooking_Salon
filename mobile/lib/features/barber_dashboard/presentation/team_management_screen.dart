import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/services/subscription_service.dart';
import 'employee_schedule_screen.dart';
import 'employee_services_screen.dart';

class Employee {
  final String id;
  final String name;
  final String phoneNumber;
  final String? profileImageUrl;
  final bool isActive;

  Employee({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.profileImageUrl,
    required this.isActive,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class TeamManagementScreen extends StatefulWidget {
  const TeamManagementScreen({super.key});

  @override
  State<TeamManagementScreen> createState() => _TeamManagementScreenState();
}

class _TeamManagementScreenState extends State<TeamManagementScreen> {
  final ApiClient _api = ApiClient();
  final SubscriptionService _subscriptionService = SubscriptionService(ApiClient());
  List<Employee> _employees = [];
  bool _isLoading = true;
  int _currentCount = 0;
  int _maxEmployees = 0;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.dio.get('/api/barber/dashboard/employees');
      final data = response.data as List;
      int maxEmp = 0;
      try {
        final sub = await _subscriptionService.getCurrentSubscription();
        if (sub != null) maxEmp = sub.maxEmployees;
      } catch (_) {}
      if (mounted) {
        setState(() {
          _employees = data.map((json) => Employee.fromJson(json)).toList();
          _currentCount = _employees.length;
          _maxEmployees = maxEmp;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('فريق العمل', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Header
                FadeIn(
                  delay: const Duration(milliseconds: 100),
                  child: _buildHeader(isDark),
                ),

                // Employees List
                Expanded(
                  child: _employees.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: _employees.length,
                          itemBuilder: (context, index) {
                            return FadeIn(
                              delay: Duration(milliseconds: 100 * (index + 1)),
                              child: _buildEmployeeCard(isDark, _employees[index]),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: _canAddEmployee()
          ? FloatingActionButton(
              onPressed: () => _showAddEmployeeDialog(isDark),
              backgroundColor: AppColors.primary,
              child: Icon(Icons.add, color: isDark ? AppColors.darkBackground : AppColors.lightBackground),
            )
          : null,
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Column(
        children: [
          Icon(Icons.people, color: AppColors.primary, size: 40),
          const SizedBox(height: 12),
          Text(
            '$_currentCount / ${_maxEmployees < 0 ? '∞' : _maxEmployees}',
            style: TextStyle(
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'الموظفين',
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 14,
            ),
          ),
          if (!_canAddEmployee()) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'وصلت الحد الأقصى — ارقِ خطةك',
                style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, color: (isDark ? AppColors.darkTextHint : AppColors.lightTextHint).withValues(alpha: 0.5), size: 80),
          const SizedBox(height: 20),
          Text(
            'لا يوجد موظفين',
            style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف حلاقين للعمل في صالونك',
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 20),
          if (_canAddEmployee())
            ElevatedButton(
              onPressed: () => _showAddEmployeeDialog(isDark),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('إضافة موظف'),
            ),
        ],
      ),
    );
  }

  Widget _buildEmployeeCard(bool isDark, Employee employee) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
            ),
            child: ClipOval(
              child: ImageHelper.displayImage(
                imageUrl: employee.profileImageUrl,
                width: 50,
                height: 50,
                placeholder: Icon(Icons.person, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  employee.name,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  employee.phoneNumber,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: employee.isActive
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              employee.isActive ? 'نشط' : 'غير نشط',
              style: TextStyle(
                color: employee.isActive ? AppColors.success : AppColors.error,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Actions
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'schedule',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('جدول الدوام'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'services',
                child: Row(
                  children: [
                    Icon(Icons.content_cut, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('الخدمات'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'toggle',
                child: Text(employee.isActive ? 'تعطيل' : 'تفعيل'),
              ),
              PopupMenuItem(
                value: 'delete',
                child: const Text('حذف', style: TextStyle(color: AppColors.error)),
              ),
            ],
            onSelected: (value) {
              if (value == 'schedule') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EmployeeScheduleScreen(
                    employeeId: employee.id,
                    employeeName: employee.name,
                  ),
                ));
              }
              if (value == 'services') {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => EmployeeServicesScreen(
                    employeeId: employee.id,
                    employeeName: employee.name,
                  ),
                ));
              }
              if (value == 'toggle') _toggleEmployee(employee);
              if (value == 'delete') _deleteEmployee(employee);
            },
          ),
        ],
      ),
    );
  }

  bool _canAddEmployee() {
    if (_maxEmployees < 0) return true; // unlimited
    return _currentCount < _maxEmployees;
  }

  void _showAddEmployeeDialog(bool isDark) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'إضافة موظف جديد',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'اسم الموظف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                    await _addEmployee(nameController.text, phoneController.text);
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('إضافة'),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _addEmployee(String name, String phone) async {
    try {
      await _api.dio.post('/api/barber/dashboard/employees', data: {
        'name': name,
        'phoneNumber': phone,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الموظف بنجاح')),
        );
        _loadEmployees();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _toggleEmployee(Employee employee) async {
    try {
      await _api.dio.put('/api/barber/dashboard/employees/${employee.id}/toggle');
      _loadEmployees();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    }
  }

  Future<void> _deleteEmployee(Employee employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الموظف'),
        content: Text('هل أنت متأكد من حذف ${employee.name}؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.dio.delete('/api/barber/dashboard/employees/${employee.id}');
        _loadEmployees();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e')),
          );
        }
      }
    }
  }
}
