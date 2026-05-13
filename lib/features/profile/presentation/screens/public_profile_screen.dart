import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/models/user.dart';
import '../providers/profile_provider.dart';
import '../providers/review_provider.dart';
import '../../../../core/widgets/walking_worker_loader.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
      ),
      body: userAsync.when(
        data: (user) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary,
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? const Icon(
                              Icons.person,
                              size: 50,
                              color: AppColors.darkBg,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, size: 18, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildRoleBadge(user.userType),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.push('/chat/${user.id}', extra: user.displayName);
                      },
                      icon: const Icon(Icons.message_outlined, size: 18),
                      label: const Text('Message'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement Hire flow
                      },
                      icon: const Icon(Icons.work_outline, size: 18),
                      label: const Text('Hire'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(user.completedJobs.toString(), 'Jobs Done'),
                  _buildStatCard(user.rating.toStringAsFixed(1), 'Rating'),
                  _buildStatCard(user.skills.length.toString(), 'Skills'),
                ],
              ),
              const SizedBox(height: 24),

              // Bio
              const Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.bio ?? 'No bio provided.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Skills
              if (user.skills.isNotEmpty) ...[
                const Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills.map((s) => _buildSkillChip(s)).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Reviews
              const Text(
                'Reviews',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              reviewsAsync.when(
                data: (reviews) {
                  if (reviews.isEmpty) {
                    return const Text(
                      'No reviews yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    );
                  }
                  return Column(
                    children: reviews.map((r) => _buildReviewTile(r)).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Text('Error loading reviews: $err'),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: WalkingWorkerLoader(label: 'Loading profile...')),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(String skill) {
    return Chip(
      label: Text(
        skill,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.borderColor),
    );
  }

  Widget _buildRoleBadge(String userType) {
    String label = 'Viewer';
    IconData icon = Icons.visibility_outlined;
    Color color = AppColors.textSecondary;

    if (userType == 'job_seeker') {
      label = 'Job Seeker';
      icon = Icons.work_outline;
      color = AppColors.primary;
    } else if (userType == 'employer') {
      label = 'Employer';
      icon = Icons.person_add_outlined;
      color = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(Map<String, dynamic> review) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                review['rating'].toString(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review['comment'] ?? 'No comment provided.',
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
