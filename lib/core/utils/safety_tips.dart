import 'package:flutter/material.dart';

/// A single safety tip with icon, title, description, and category.
class SafetyTip {
  const SafetyTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
  });

  final IconData icon;
  final String title;
  final String description;
  final SafetyCategory category;
}

enum SafetyCategory {
  payments('Payments & Escrow'),
  communication('Communication'),
  inPerson('In-Person Meetings'),
  account('Account Security'),
  general('General Safety');

  const SafetyCategory(this.label);
  final String label;
}

class SafetyTipsData {
  static const List<SafetyTip> allTips = [
    // --- Payments ---
    SafetyTip(
      icon: Icons.lock_rounded,
      title: 'Never pay outside the app',
      description: 'All payments must go through our escrow system. '
          'If someone asks you to pay via EFT, WhatsApp, or any external method, '
          'report them immediately. Escrow protects both parties.',
      category: SafetyCategory.payments,
    ),
    SafetyTip(
      icon: Icons.account_balance_wallet_rounded,
      title: 'How escrow works',
      description: 'When you place an order, the money is held securely by the platform. '
          'The seller only gets paid once you confirm the work is complete. '
          "If there's a dispute, we review and decide the outcome.",
      category: SafetyCategory.payments,
    ),
    SafetyTip(
      icon: Icons.receipt_long_rounded,
      title: 'Keep receipts & records',
      description: 'Save all your order confirmations, receipts, and communications '
          'within the app. This helps us resolve disputes faster and more accurately.',
      category: SafetyCategory.payments,
    ),
    SafetyTip(
      icon: Icons.monetization_on_outlined,
      title: 'Beware of "too good to be true" offers',
      description: 'If a job or service is offered at an unusually low price or promises '
          "unrealistic returns, it's likely a scam. Trust your instincts.",
      category: SafetyCategory.payments,
    ),

    // --- Communication ---
    SafetyTip(
      icon: Icons.chat_bubble_outline_rounded,
      title: 'Keep conversations on the app',
      description: 'Always communicate through the in-app chat. '
          'This creates a record that can be reviewed if issues arise. '
          'Never move conversations to WhatsApp, Telegram, or other platforms.',
      category: SafetyCategory.communication,
    ),
    SafetyTip(
      icon: Icons.phone_forwarded_outlined,
      title: 'Protect your phone number',
      description: 'Only share your phone number after a job is confirmed and you\u2019ve '
          'agreed on terms. You can control who sees your contact info in Privacy Settings.',
      category: SafetyCategory.communication,
    ),
    SafetyTip(
      icon: Icons.verified_user_rounded,
      title: 'Check user verification status',
      description: 'Look for the gold verification badge on user profiles. '
          'Verified users have completed our ID verification process. '
          'Always prefer verified users for high-value transactions.',
      category: SafetyCategory.communication,
    ),

    // --- In-Person ---
    SafetyTip(
      icon: Icons.people_outline_rounded,
      title: 'Meet in public places',
      description: 'For services like cleaning, tutoring, or handyman work, '
          'arrange to meet in a public place first. Let a friend or family member '
          "know where you're going and who you're meeting.",
      category: SafetyCategory.inPerson,
    ),
    SafetyTip(
      icon: Icons.access_time_rounded,
      title: 'Daytime meetings only',
      description: 'Schedule first-time in-person meetings during daylight hours. '
          "Avoid early morning or late evening meetups until you've established trust.",
      category: SafetyCategory.inPerson,
    ),
    SafetyTip(
      icon: Icons.emergency_rounded,
      title: 'Share your location',
      description: 'Share your live location with a trusted friend or family member '
          "when going to a new client's home for a service. "
          'Use WhatsApp or Google Maps location sharing.',
      category: SafetyCategory.inPerson,
    ),
    SafetyTip(
      icon: Icons.warning_amber_rounded,
      title: 'Trust your instincts',
      description: "If something feels off, it probably is. You can cancel a job "
          'or decline a service at any time. Your safety comes first \u2014 always.',
      category: SafetyCategory.inPerson,
    ),

    // --- Account Security ---
    SafetyTip(
      icon: Icons.password_rounded,
      title: 'Use a strong password',
      description: "Use a unique password that you don't use on other sites. "
          'A strong password has at least 12 characters with a mix of letters, '
          'numbers, and symbols.',
      category: SafetyCategory.account,
    ),
    SafetyTip(
      icon: Icons.phonelink_lock_rounded,
      title: 'Never share your OTP',
      description: 'We will never ask for your one-time PIN or verification code. '
          "Anyone who asks for your OTP is trying to steal your account. "
          'Report them immediately.',
      category: SafetyCategory.account,
    ),
    SafetyTip(
      icon: Icons.logout_rounded,
      title: 'Log out on shared devices',
      description: 'Always log out of your account when using a shared or public device. '
          'This prevents others from accessing your wallet and personal information.',
      category: SafetyCategory.account,
    ),

    // --- General ---
    SafetyTip(
      icon: Icons.flag_rounded,
      title: 'Report suspicious behaviour',
      description: 'If someone makes you feel uncomfortable or tries to break the rules, '
          'report them immediately. Go to their profile or tap the three dots in chat '
          'to report. All reports are reviewed by our team.',
      category: SafetyCategory.general,
    ),
    SafetyTip(
      icon: Icons.block_rounded,
      title: 'Blocking users',
      description: 'You can block any user at any time. Blocked users cannot message you '
          "or view your profile. Go to the chat menu or their profile to block them.",
      category: SafetyCategory.general,
    ),
    SafetyTip(
      icon: Icons.star_rounded,
      title: 'Leave honest reviews',
      description: 'After completing a job, leave an honest review and rating. '
          'Your feedback helps the community make informed decisions '
          'and holds users accountable.',
      category: SafetyCategory.general,
    ),
    SafetyTip(
      icon: Icons.help_center_rounded,
      title: 'Need help? Contact support',
      description: 'If you encounter any issues, need to report a problem, or have questions '
          'about safety, contact our support team at support@illdoit.co.za. '
          "We're here to help 24/7.",
      category: SafetyCategory.general,
    ),
  ];

  /// Get tips relevant to a specific context.
  static List<SafetyTip> tipsForCategory(SafetyCategory category) =>
      allTips.where((t) => t.category == category).toList();

  /// Get a single random tip to show as a banner.
  static SafetyTip get randomTip =>
      allTips[(DateTime.now().millisecondsSinceEpoch ~/ 10000) % allTips.length];

  /// Get a short single-line safety tip for inline display.
  static const List<String> quickTips = [
    '\u2022 Never pay outside the app \u2014 escrow protects you.',
    '\u2022 Keep all conversations on the in-app chat.',
    '\u2022 Meet in public places for physical jobs.',
    '\u2022 Check for the verification badge before transacting.',
    '\u2022 Report suspicious users immediately.',
    '\u2022 Never share your OTP with anyone.',
    '\u2022 Leave honest reviews to help the community.',
  ];
}
