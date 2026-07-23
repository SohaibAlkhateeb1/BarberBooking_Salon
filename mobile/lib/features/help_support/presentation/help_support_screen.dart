import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/animations/app_animations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
        title: Text(
          'المساعدة والدعم',
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeIn(
              child: _buildSectionTitle('الأسئلة الشائعة', isDark),
            ),
            const SizedBox(height: 12),
            ...List.generate(5, (index) {
              final questions = [
                'كيف أحجز موعد؟',
                'كيف أقوم بإلغاء الحجز؟',
                'هل يمكنني تعديل الحجز؟',
                'كيف أقيّم الحلاق؟',
                'كيف أضيف حلاق للمفضلة؟',
              ];
              final answers = [
                'اختر الحلاق المناسب من القائمة، ثم اختر الخدمة والوقت المناسب، وأكد الحجز.',
                'اذهب إلى صفحة "المواعيد"، اختر الحجز المطلوب، ثم اضغط "إلغاء الحجز".',
                'نعم، يمكنك إعادة جدولة الحجز من صفحة تفاصيل الحجز بتحديد وقت جديد.',
                'بعد إتمام الحجز، اذهب إلى صفحة تفاصيل الحجز واضغط "قيّم تجربتك".',
                'اذهب إلى صفحة الحلاق واضغط على أيقونة القلب لإضافته للمفضلة.',
              ];
              return FadeIn(
                child: _buildFaqItem(questions[index], answers[index], isDark),
              );
            }),
            const SizedBox(height: 24),
            FadeIn(
              child: _buildSectionTitle('تواصل معنا', isDark),
            ),
            const SizedBox(height: 12),
            ...List.generate(3, (index) {
              final icons = [Icons.phone_outlined, Icons.email_outlined, Icons.chat_bubble_outline];
              final titles = ['الهاتف', 'البريد الإلكتروني', 'الدردشة المباشرة'];
              final subtitles = ['+970 59 123 4567', 'support@barberbooking.ps', 'متاح يومياً من 9 صباحاً - 9 مساءً'];
              return FadeIn(
                child: _buildContactOption(context, icons[index], titles[index], subtitles[index], () {}, isDark),
              );
            }),
            const SizedBox(height: 24),
            FadeIn(
              child: _buildSectionTitle('المعلومات القانونية', isDark),
            ),
            const SizedBox(height: 12),
            FadeIn(
              child: _buildInfoItem('سياسة الخصوصية', () {}, isDark),
            ),
            FadeIn(
              child: _buildInfoItem('شروط الاستخدام', () {}, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(
          question,
          style: TextStyle(
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconColor: AppColors.primary,
        collapsedIconColor: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        children: [
          Text(
            answer,
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary, fontSize: 13),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoItem(String title, VoidCallback onTap, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 15),
        ),
        trailing: Icon(Icons.arrow_forward_ios, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint, size: 16),
        onTap: onTap,
      ),
    );
  }
}
