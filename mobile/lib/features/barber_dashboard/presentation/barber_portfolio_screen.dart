import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/image_helper.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/animations/app_animations.dart';

class PortfolioImageItem {
  final String id;
  final String imageUrl;
  final String? caption;
  final int sortOrder;

  PortfolioImageItem({required this.id, required this.imageUrl, this.caption, required this.sortOrder});

  factory PortfolioImageItem.fromJson(Map<String, dynamic> json) {
    return PortfolioImageItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? '',
      caption: json['caption'],
      sortOrder: json['sortOrder'] ?? 0,
    );
  }
}

class BarberPortfolioScreen extends StatefulWidget {
  const BarberPortfolioScreen({super.key});

  @override
  State<BarberPortfolioScreen> createState() => _BarberPortfolioScreenState();
}

class _BarberPortfolioScreenState extends State<BarberPortfolioScreen> {
  final ApiClient _api = ApiClient();
  final ImagePicker _picker = ImagePicker();
  List<PortfolioImageItem> _images = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _maxPhotos = -1;
  int _currentPhotosCount = 0;

  @override
  void initState() {
    super.initState();
    _loadImages();
    _loadSubscriptionInfo();
  }

  Future<void> _loadSubscriptionInfo() async {
    try {
      final response = await _api.dio.get('/api/subscriptions/current');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _maxPhotos = data['maxPhotos'] ?? -1;
          _currentPhotosCount = data['currentPhotosCount'] ?? _images.length;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadImages() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final response = await _api.dio.get('/api/barber/portfolio');
      final data = response.data;
      if (data is List) {
        setState(() {
          _images = data.map((e) => PortfolioImageItem.fromJson(e)).toList();
          _currentPhotosCount = _images.length;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() { _isLoading = false; _hasError = true; });
    }
    _loadSubscriptionInfo();
  }

  Future<void> _addImage() async {
    if (_maxPhotos > 0 && _currentPhotosCount >= _maxPhotos) {
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('تم الوصول للحد الأقصى', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'لقد وصلت للحد الأقصى من الصور ($_maxPhotos صورة). قم بالترقية لخطة أعلى لإضافة المزيد.',
            style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('حسناً', style: TextStyle(color: AppColors.primary))),
          ],
        ),
      );
      return;
    }

    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024, imageQuality: 80);
    if (picked == null) return;

    try {
      List<int> bytes;
      bytes = await picked.readAsBytes();
      final base64Image = base64Encode(bytes);

      if (!mounted) return;

      String? caption;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      await showDialog(
        context: context,
        builder: (ctx) {
          final captionController = TextEditingController();
          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('وصف الصورة', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
            content: TextField(
              controller: captionController,
              style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              decoration: InputDecoration(
                hintText: 'مثال: قص شعر عصري',
                hintStyle: TextStyle(color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('إلغاء', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
              TextButton(
                onPressed: () {
                  caption = captionController.text;
                  Navigator.pop(ctx);
                },
                child: const Text('حفظ', style: TextStyle(color: AppColors.primary)),
              ),
            ],
          );
        },
      );

      await _api.dio.post('/api/barber/portfolio', data: {
        'imageUrl': 'data:image/jpeg;base64,$base64Image',
        'caption': caption,
        'sortOrder': _images.length,
      });

      _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تمت إضافة الصورة'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _deleteImage(PortfolioImageItem image) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('حذف الصورة', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary)),
        content: Text('هل أنت متأكد من حذف هذه الصورة؟', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('إلغاء', style: TextStyle(color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _api.dio.delete('/api/barber/portfolio/${image.id}');
      _loadImages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الصورة'), backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
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
        title: Text('أعمالي', style: TextStyle(color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addImage,
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: isDark ? AppColors.darkBackground : AppColors.lightBackground),
      ),
      body: Column(
        children: [
          if (_maxPhotos > 0)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _currentPhotosCount >= _maxPhotos
                    ? AppColors.error.withValues(alpha: 0.1)
                    : AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _currentPhotosCount >= _maxPhotos ? Icons.warning_amber : Icons.photo_library_outlined,
                    color: _currentPhotosCount >= _maxPhotos ? AppColors.error : AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_currentPhotosCount / $_maxPhotos صورة',
                    style: TextStyle(
                      color: _currentPhotosCount >= _maxPhotos ? AppColors.error : AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
          ? _buildSkeletonGrid()
          : _hasError
              ? ErrorState(onRetry: _loadImages)
              : _images.isEmpty
                  ? const EmptyState(type: EmptyStateType.generic)
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _images.length,
                      itemBuilder: (context, index) {
                        final image = _images[index];
                        return FadeIn(
                          delay: Duration(milliseconds: index * 50),
                          child: _buildImageCard(image),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 4,
        itemBuilder: (context, index) => SkeletonLoader(height: 180, borderRadius: 12),
      ),
    );
  }

  Widget _buildImageCard(PortfolioImageItem image) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? AppColors.darkCardBorder : AppColors.lightCardBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: ImageHelper.displayImage(
            imageUrl: image.imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: Container(
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
              child: Icon(Icons.image, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            ),
            errorWidget: Container(
              color: isDark ? AppColors.darkSurfaceLight : AppColors.lightSurfaceVariant,
              child: Icon(Icons.broken_image, color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint),
            ),
          ),
        ),
        if (image.caption != null && image.caption!.isNotEmpty)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
              child: Text(
                image.caption!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: () => _deleteImage(image),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_outline, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }
}
