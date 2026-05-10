import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/profile_provider.dart';

class VerificationCenterScreen extends ConsumerWidget {
  const VerificationCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Verification Center'),
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          user.isVerified
                              ? Icons.verified
                              : user.verificationStatus == 'pending'
                                  ? Icons.hourglass_empty
                                  : user.verificationStatus == 'rejected'
                                      ? Icons.report_problem
                                      : Icons.shield_outlined,
                          size: 48,
                          color: AppColors.darkBg,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.isVerified
                                    ? 'Verified Identity'
                                    : user.verificationStatus == 'pending'
                                        ? 'Review in Progress'
                                        : user.verificationStatus == 'rejected'
                                            ? 'Action Required'
                                            : 'Start Verification',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.darkBg,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user.isVerified
                                    ? 'Your account is fully verified and ready for trusted work.'
                                    : user.verificationStatus == 'pending'
                                        ? 'We are reviewing your documents. This usually takes 24-48 hours.'
                                        : user.verificationStatus == 'rejected'
                                            ? 'Your previous submission was not approved. Resubmit clearer documents to continue.'
                                            : 'Complete identity verification to unlock higher-value jobs and faster payouts.',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.darkBg,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!user.isVerified) ...[
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: user.verificationStatus == 'pending'
                            ? OutlinedButton(
                                onPressed: null,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.darkBg,
                                  side: const BorderSide(color: AppColors.darkBg),
                                ),
                                child: const Text('Waiting for review'),
                              )
                            : ElevatedButton(
                                onPressed: () => context.push(AppRoutes.idVerification),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.darkBg,
                                  foregroundColor: AppColors.primary,
                                ),
                                child: Text(user.verificationStatus == 'rejected' ? 'Resubmit documents' : 'Submit verification'),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Verification Steps',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Level 1: Phone & Email (Assumed done if they are here)
              _buildVerificationStep(
                title: 'Contact Verification',
                subtitle: 'Email and Phone Number',
                isCompleted: true, // Always true if they can access profile?
                icon: Icons.contact_phone_outlined,
              ),

              // Level 2: ID Verification
              _buildVerificationStep(
                title: 'Identity Verification',
                subtitle: 'South African ID or Passport',
                isCompleted: user.isVerified,
                isPending: user.verificationStatus == 'pending',
                icon: Icons.badge_outlined,
                onTap: (user.isVerified || user.verificationStatus == 'pending') ? null : () {
                  context.push(AppRoutes.idVerification);
                },
              ),

              // Level 3: Selfie Verification
              _buildVerificationStep(
                title: 'Face Verification',
                subtitle: 'Liveness check with your camera',
                isCompleted: user.isVerified, 
                isPending: user.verificationStatus == 'pending',
                icon: Icons.face_outlined,
                onTap: (user.isVerified || user.verificationStatus == 'pending') ? null : () {
                  context.push(AppRoutes.idVerification); // Same flow for now
                },
              ),

              const SizedBox(height: 40),
              
              const Text(
                'Why verify?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              _buildWhyItem(Icons.trending_up, 'Higher ranking in search results'),
              _buildWhyItem(Icons.lock_outline, 'Access to high-budget jobs'),
              _buildWhyItem(Icons.verified_outlined, 'Official "Verified" badge on profile'),
              _buildWhyItem(Icons.account_balance_wallet_outlined, 'Faster payment withdrawals'),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildVerificationStep({
    required String title,
    required String subtitle,
    required bool isCompleted,
    bool isPending = false,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted 
            ? AppColors.primary.withOpacity(0.5) 
            : isPending 
              ? AppColors.warning.withOpacity(0.5) 
              : AppColors.borderColor,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCompleted 
              ? AppColors.primary.withOpacity(0.1) 
              : isPending 
                ? AppColors.warning.withOpacity(0.1) 
                : AppColors.darkBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted 
              ? AppColors.primary 
              : isPending 
                ? AppColors.warning 
                : AppColors.textSecondary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isCompleted || isPending ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
        trailing: isCompleted
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : isPending
            ? const Icon(Icons.hourglass_bottom, color: AppColors.warning)
            : const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _buildWhyItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
