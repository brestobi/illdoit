import 'package:flutter/material.dart';

/// Describes the visual art for a category: an emoji + a gradient color pair.
class CategoryArt {
  const CategoryArt(this.emoji, this.gradientStart, this.gradientEnd);

  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;

  List<Color> get gradientColors => [gradientStart, gradientEnd];
}

class CategoryUtils {
  /// Returns a rich [CategoryArt] with emoji + gradient colours for the given category name.
  static CategoryArt getArtForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      // ---- Creative / Design ----
      case 'design':
      case 'logo design':
      case 'ui/ux design':
      case 'illustration':
      case 'graphic design':
        return const CategoryArt('🎨', Color(0xFF7C4DFF), Color(0xFF448AFF));

      // ---- Development ----
      case 'dev':
      case 'development':
      case 'web development':
        return const CategoryArt('💻', Color(0xFF00BCD4), Color(0xFF1DE9B6));
      case 'mobile app dev':
        return const CategoryArt('📱', Color(0xFF00BCD4), Color(0xFF1DE9B6));
      case 'software testing':
        return const CategoryArt('🧪', Color(0xFF26A69A), Color(0xFF80CBC4));
      case 'blockchain dev':
        return const CategoryArt('⛓️', Color(0xFF5C6BC0), Color(0xFF9FA8DA));
      case 'ai/machine learning':
        return const CategoryArt('🤖', Color(0xFF6A1B9A), Color(0xFFCE93D8));

      // ---- Writing ----
      case 'writing':
      case 'content writing':
      case 'copywriting':
      case 'cv writing':
        return const CategoryArt('✍️', Color(0xFFFF6F00), Color(0xFFFFAB00));

      // ---- Marketing ----
      case 'marketing':
      case 'digital marketing':
      case 'social media management':
      case 'seo services':
        return const CategoryArt('📈', Color(0xFFE91E63), Color(0xFFFF4081));

      // ---- Video ----
      case 'video':
      case 'video editing':
        return const CategoryArt('🎬', Color(0xFFF44336), Color(0xFFFF7043));

      // ---- Music / Audio ----
      case 'music':
        return const CategoryArt('🎵', Color(0xFF9C27B0), Color(0xFFE040FB));
      case 'voice over':
        return const CategoryArt('🎤', Color(0xFFAB47BC), Color(0xFFF48FB1));

      // ---- Photography ----
      case 'photo':
      case 'photography':
        return const CategoryArt('📸', Color(0xFF4CAF50), Color(0xFF69F0AE));

      // ---- Tutoring ----
      case 'tutor':
      case 'tutoring':
      case 'tutor (in-person)':
        return const CategoryArt('📚', Color(0xFF2196F3), Color(0xFF40C4FF));

      // ---- Support / Admin ----
      case 'support':
      case 'virtual assistant':
      case 'data entry':
      case 'tech support':
        return const CategoryArt('🤝', Color(0xFF607D8B), Color(0xFF90A4AE));

      // ---- Trade Services ----
      case 'plumbing':
        return const CategoryArt('🔧', Color(0xFF546E7A), Color(0xFFB0BEC5));
      case 'electrical':
      case 'electrical work':
        return const CategoryArt('⚡', Color(0xFFF9A825), Color(0xFFFFEE58));
      case 'carpentry':
        return const CategoryArt('🪚', Color(0xFF795548), Color(0xFFA1887F));
      case 'painting':
        return const CategoryArt('🖌️', Color(0xFFEF6C00), Color(0xFFFFB74D));
      case 'handyman':
        return const CategoryArt('🛠️', Color(0xFF6D4C41), Color(0xFFBCAAA4));
      case 'welding':
        return const CategoryArt('🔥', Color(0xFFBF360C), Color(0xFFFF8A65));

      // ---- Cleaning ----
      case 'cleaning':
      case 'cleaning services':
      case 'laundry services':
        return const CategoryArt('🧹', Color(0xFF00897B), Color(0xFF4DB6AC));

      // ---- Gardening ----
      case 'gardening':
      case 'gardening & landscaping':
        return const CategoryArt('🌿', Color(0xFF689F38), Color(0xFF8BC34A));

      // ---- Auto ----
      case 'auto repair':
        return const CategoryArt('🚗', Color(0xFF37474F), Color(0xFF78909C));

      // ---- Delivery / Moving ----
      case 'delivery':
      case 'delivery & courier':
        return const CategoryArt('🚚', Color(0xFFFF5722), Color(0xFFFF7043));
      case 'moving & hauling':
        return const CategoryArt('📦', Color(0xFFE64A19), Color(0xFFFF8A65));

      // ---- Health & Fitness ----
      case 'personal training':
        return const CategoryArt('💪', Color(0xFFD50000), Color(0xFFFF1744));
      case 'yoga instruction':
        return const CategoryArt('🧘', Color(0xFFAD1457), Color(0xFFF06292));
      case 'massage therapy':
        return const CategoryArt('💆', Color(0xFF6A1B9A), Color(0xFFE040FB));

      // ---- Beauty ----
      case 'hairdressing':
        return const CategoryArt('💇', Color(0xFFAD1457), Color(0xFFF48FB1));
      case 'makeup artist':
        return const CategoryArt('💄', Color(0xFF880E4F), Color(0xFFF06292));
      case 'tailoring':
        return const CategoryArt('🧵', Color(0xFF4E342E), Color(0xFFA1887F));

      // ---- Catering ----
      case 'catering':
        return const CategoryArt('🍳', Color(0xFFFF6F00), Color(0xFFFFB300));

      // ---- Child / Pet Care ----
      case 'babysitting':
        return const CategoryArt('👶', Color(0xFF00897B), Color(0xFF80CBC4));
      case 'pet sitting/walking':
      case 'pet sitting':
        return const CategoryArt('🐾', Color(0xFF6D4C41), Color(0xFFD7CCC8));

      // ---- Security ----
      case 'security services':
        return const CategoryArt('🛡️', Color(0xFF263238), Color(0xFF607D8B));

      // ---- Events ----
      case 'event planning':
        return const CategoryArt('🎉', Color(0xFFFF4081), Color(0xFFFFD740));

      // ---- Construction ----
      case 'construction':
      case 'roofing':
        return const CategoryArt('🏗️', Color(0xFFE65100), Color(0xFFFFB74D));
      case 'tiling':
        return const CategoryArt('🧱', Color(0xFFBF360C), Color(0xFFFF8A65));

      // ---- Default fallback ----
      default:
        return const CategoryArt('🔍', Color(0xFF757575), Color(0xFFBDBDBD));
    }
  }

  /// Legacy icon-based lookup – kept for backward compatibility.
  static IconData getIconForCategory(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'design':
      case 'logo design':
      case 'ui/ux design':
      case 'illustration':
      case 'graphic design':
        return Icons.palette_outlined;
      case 'dev':
      case 'development':
      case 'web development':
      case 'mobile app dev':
      case 'software testing':
      case 'blockchain dev':
      case 'ai/machine learning':
        return Icons.code_rounded;
      case 'writing':
      case 'content writing':
      case 'copywriting':
      case 'cv writing':
        return Icons.edit_note_rounded;
      case 'marketing':
      case 'digital marketing':
      case 'social media management':
      case 'seo services':
        return Icons.campaign_outlined;
      case 'video':
      case 'video editing':
        return Icons.videocam_outlined;
      case 'music':
      case 'voice over':
        return Icons.music_note_outlined;
      case 'photo':
      case 'photography':
        return Icons.camera_alt_outlined;
      case 'tutor':
      case 'tutoring':
      case 'tutor (in-person)':
        return Icons.school_outlined;
      case 'support':
      case 'virtual assistant':
      case 'data entry':
      case 'tech support':
        return Icons.support_agent_outlined;
      case 'plumbing':
        return Icons.plumbing_rounded;
      case 'electrical':
      case 'electrical work':
        return Icons.electrical_services_rounded;
      case 'carpentry':
        return Icons.carpenter_rounded;
      case 'cleaning':
      case 'cleaning services':
      case 'laundry services':
        return Icons.cleaning_services_rounded;
      case 'gardening':
      case 'gardening & landscaping':
        return Icons.yard_outlined;
      case 'painting':
        return Icons.format_paint_outlined;
      case 'handyman':
        return Icons.build_outlined;
      case 'auto repair':
        return Icons.directions_car_outlined;
      case 'delivery':
      case 'delivery & courier':
      case 'moving & hauling':
        return Icons.delivery_dining_rounded;
      case 'personal training':
      case 'yoga instruction':
      case 'massage therapy':
        return Icons.fitness_center_rounded;
      case 'hairdressing':
      case 'makeup artist':
      case 'tailoring':
        return Icons.content_cut_rounded;
      case 'catering':
        return Icons.restaurant_rounded;
      case 'babysitting':
      case 'pet sitting/walking':
        return Icons.child_care_rounded;
      case 'security services':
        return Icons.security_rounded;
      case 'event planning':
        return Icons.event_rounded;
      case 'construction':
      case 'roofing':
      case 'tiling':
      case 'welding':
        return Icons.architecture_rounded;
      default:
        return Icons.category_outlined;
    }
  }
}
