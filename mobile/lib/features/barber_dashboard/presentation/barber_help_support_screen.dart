import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../support/data/support_service.dart';
import '../presentation/ticket_detail_screen.dart';
import '../presentation/submit_ticket_screen.dart';

class BarberHelpSupportScreen extends StatefulWidget {
  const BarberHelpSupportScreen({super.key});

  @override
  State<BarberHelpSupportScreen> createState() => _BarberHelpSupportScreenState();
}

class _BarberHelpSupportScreenState extends State<BarberHelpSupportScreen> {
  final SupportService _supportService = SupportService();
  List<SupportTicketModel> _tickets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    try {
      final tickets = await _supportService.getMyTickets();
      if (mounted) {
        setState(() {
          _tickets = tickets;
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
        title: Text('المساعدة والدعم', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActions(isDark),
              const SizedBox(height: 24),
              _buildFAQSection(isDark),
              const SizedBox(height: 24),
              _buildTicketHistory(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'كيف يمكننا المساعدة؟',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'اختر نوع المشكلة أو أرسل تذكرة مباشرة',
          style: TextStyle(
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildActionCard(
              isDark,
              icon: Icons.bug_report_outlined,
              title: 'مشكلة تقنية',
              subtitle: 'التطبيق لا يعمل بشكل صحيح',
              onTap: () => _submitTicket('Technical'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(
              isDark,
              icon: Icons.calendar_today_outlined,
              title: 'مشكلة بالحجز',
              subtitle: 'مشكلة تتعلق بالمواعيد',
              onTap: () => _submitTicket('Booking'),
            )),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildActionCard(
              isDark,
              icon: Icons.payments_outlined,
              title: 'مشكلة بالدفع',
              subtitle: ' Issues with payments',
              onTap: () => _submitTicket('Payment'),
            )),
            const SizedBox(width: 12),
            Expanded(child: _buildActionCard(
              isDark,
              icon: Icons.lightbulb_outline,
              title: 'اقتراح ميزة',
              subtitle: 'شاركنا أفكارك',
              onTap: () => _submitTicket('Suggestion'),
            )),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection(bool isDark) {
    final faqs = [
      {'q': 'كيف أغير موعد حجزي؟', 'a': 'يمكنك إعادة جدولة الحجز من شاشة التفاصيل قبل أن يبدأ الحلاق بالخدمة.'},
      {'q': 'كيف أضيف موظف جديد؟', 'a': 'من شاشة "الفريق" في لوحة التحكم، اضغط "إضافة موظف" وأدخل بياناته.'},
      {'q': 'ماذا يحدث عند انتهاء الاشتراك؟', 'a': 'تتم ترقية الحساب للخطة الأساسية وتفقد الميزات المدفوعة.'},
      {'q': 'كيف أتواصل مع فريق الدعم؟', 'a': 'أرسل تذكرة دعم من هذه الشاشة وسيتم الرد خلال وقت قصير حسب خطتك.'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الأسئلة الشائعة',
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...faqs.map((faq) => _buildFAQItem(faq['q']!, faq['a']!, isDark)),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        iconColor: AppColors.primary,
        collapsedIconColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        title: Text(
          question,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHistory(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'تذاكري',
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              '${_tickets.length} تذكرة',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          ...List.generate(3, (_) => _buildSkeletonTicket(isDark))
        else if (_tickets.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.support_agent, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                Text(
                  'لا توجد تذاكر',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'لم ترسل أي تذكرة دعم بعد',
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          ..._tickets.map((ticket) => _buildTicketCard(ticket, isDark)),
      ],
    );
  }

  Widget _buildSkeletonTicket(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 60, height: 20, decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(6))),
              const Spacer(),
              Container(width: 50, height: 20, decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(6))),
            ],
          ),
          const SizedBox(height: 10),
          Container(width: 200, height: 16, decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 8),
          Container(width: 120, height: 14, decoration: BoxDecoration(color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant, borderRadius: BorderRadius.circular(6))),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicketModel ticket, bool isDark) {
    Color statusColor;
    switch (ticket.status) {
      case 'Open':
        statusColor = Colors.orange;
        break;
      case 'In Progress':
        statusColor = Colors.blue;
        break;
      case 'Resolved':
        statusColor = AppColors.success;
        break;
      case 'Closed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = AppColors.textSecondary;
    }

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TicketDetailScreen(ticketId: ticket.id)),
        );
        _loadTickets();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(ticket.priority).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.ticketNumber,
                    style: TextStyle(
                      color: _getPriorityColor(ticket.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.statusArabic,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.subject,
              style: TextStyle(
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  ticket.ticketTypeArabic,
                  style: TextStyle(
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${ticket.priorityArabic}',
                  style: TextStyle(
                    color: _getPriorityColor(ticket.priority),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return AppColors.error;
      case 'High':
        return Colors.orange;
      default:
        return AppColors.primary;
    }
  }

  void _submitTicket(String type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitTicketScreen(initialType: type),
      ),
    );
    _loadTickets();
  }
}
