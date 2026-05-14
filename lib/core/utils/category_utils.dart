import 'package:flutter/material.dart';

class CategoryUtils {
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
