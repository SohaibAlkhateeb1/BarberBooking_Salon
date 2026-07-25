import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({required this.id, required this.title, required this.message, required this.type, required this.isRead, required this.createdAt});

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'booking',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  bool get isCancellation => type == 'cancellation';
}

class BarberNotificationsScreen extends StatefulWidget {
  const BarberNotificationsScreen({super.key});

  @override
  State<BarberNotificationsScreen> createState() => _BarberNotificationsScreenState();
}

class _BarberNotificationsScreenState extends State<BarberNotificationsScreen> {
  final ApiClient _api = ApiClient();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadNotifications();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    if (_notifications.isEmpty) {
      setState(() => _isLoading = true);
    }
    try {
      final response = await _api.dio.get('/api/notifications');
      final data = response.data;
      final List? list = data is Map ? data['notifications'] as List? : data as List?;
      if (list != null) {
        setState(() {
          _notifications = list.map((e) => NotificationModel.fromJson(e)).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.dio.put('/api/notifications/read-all');
      _loadNotifications();
    } catch (_) {}
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الكل', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        content: Text('هل أنت متأكد من حذف جميع الإشعارات؟', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _api.dio.delete('/api/notifications');
      _loadNotifications();
    } catch (_) {}
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays} يوم مضى';
    if (diff.inHours > 0) return '${diff.inHours} ساعة مضت';
    if (diff.inMinutes > 0) return '${diff.inMinutes} دقيقة مضت';
    return 'الآن';
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
        title: Text('الإشعارات', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          if (_notifications.isNotEmpty) ...[
            TextButton(
              onPressed: _markAllRead,
              child: const Text('قراءة الكل', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
            TextButton(
              onPressed: _deleteAll,
              child: const Text('حذف الكل', style: TextStyle(color: AppColors.error, fontSize: 13)),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? _buildLoadingSkeleton()
          : _notifications.isEmpty
              ? const EmptyState(type: EmptyStateType.notifications)
              : _buildNotificationsList(isDark),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(5, (_) => SkeletonListTile()),
      ),
    );
  }

  Widget _buildNotificationsList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notif = _notifications[index];
        final notifColor = notif.isCancellation ? AppColors.error : AppColors.success;
        final notifBorder = notif.isCancellation
            ? AppColors.error.withValues(alpha: 0.3)
            : AppColors.success.withValues(alpha: 0.3);
        final unreadBg = notif.isCancellation
            ? AppColors.error.withValues(alpha: 0.1)
            : AppColors.success.withValues(alpha: 0.1);
        return FadeIn(
          delay: Duration(milliseconds: 40 * index),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notif.isRead ? (isDark ? AppColors.darkSurface : AppColors.lightSurface) : unreadBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notif.isRead ? (isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder) : notifBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: notifColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    notif.isCancellation ? Icons.cancel_outlined : Icons.notifications_outlined,
                    color: notifColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notif.title, style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 14, fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(notif.message, style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13)),
                      const SizedBox(height: 4),
                      Text(_formatDate(notif.createdAt), style: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
