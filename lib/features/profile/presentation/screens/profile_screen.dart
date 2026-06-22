import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../providers/profile_provider.dart';
import '../providers/review_provider.dart';
import '../../../wallet/presentation/providers/wallet_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final totalEarnedAsync = ref.watch(totalEarnedProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(AppRoutes.settings);
            },
          ),
        ],
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviewsAsync = ref.watch(userReviewsProvider(user.id));
          return SingleChildScrollView(
      //...

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
                      backgroundColor: theme.primaryColor,
                      backgroundImage: user.avatarUrl != null
                          ? CachedNetworkImageProvider(user.avatarUrl!)
                          : null,
                      child: user.avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: theme.colorScheme.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.displayName,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleBadge(context, user.userType),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.verificationCenter),
                      child: user.isVerified
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 14,
                                    color: theme.primaryColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verified',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified_user_outlined,
                                    size: 14,
                                    color: theme.textTheme.bodySmall?.color,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Verify Account',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodySmall?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Stats
              _buildStatSection(context, user, totalEarnedAsync),
              const SizedBox(height: 24),

              // Bio
              Text(
                'About',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user.bio ?? 'No bio yet.',
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                ),
              ),
              const SizedBox(height: 24),

              // Skills
              if (user.skills.isNotEmpty) ...[
                Text(
                  'Skills',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: user.skills.map((s) => _buildSkillChip(context, s)).toList(),
                ),
                const SizedBox(height: 24),
              ],

              _buildReviewSection(context, reviewsAsync),
              const SizedBox(height: 24),
              // ... buttons ...

              // Action Buttons
              if (user.userType == 'viewer')
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      context.push(AppRoutes.onboarding);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                    ),
                    child: const Text('Upgrade to Job Seeker / Employer'),
                  ),
                ),
              if (user.userType == 'viewer') const SizedBox(height: 12),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.wallet);
                  },
                  child: const Text('Wallet'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.editProfile);
                  },
                  child: const Text('Edit Profile'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.services);
                  },
                  child: const Text('My Services'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.myOrders);
                  },
                  child: const Text('My Orders'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    context.push(AppRoutes.myApplications);
                  },
                  child: const Text('My Applications'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () async {
                    await ref.read(supabaseServiceProvider).signOut();
                    if (context.mounted) {
                      context.go(AppRoutes.login);
                    }
                  },
                  child: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.refresh(profileProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: const MainBottomNavBar(currentIndex: 4),
  );
}

Widget _buildStatSection(BuildContext context, dynamic user, AsyncValue<double> totalEarnedAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatCard(context, user.completedJobs.toString(), 'Completed'),
        _buildStatCard(context, user.rating.toString(), 'Rating'),
        totalEarnedAsync.when(
          data: (earned) => _buildStatCard(context, 'R${earned.toStringAsFixed(0)}', 'Earned'),
          loading: () => _buildStatCard(context, '...', 'Earned'),
          error: (_, __) => _buildStatCard(context, 'R0', 'Earned'),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: theme.primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildSkillChip(BuildContext context, String skill) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        skill,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyMedium?.color,
        ),
      ),
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(color: theme.dividerColor),
    );
  }

  Widget _buildRoleBadge(BuildContext context, String userType) {
    final theme = Theme.of(context);
    String label = 'Viewer';
    IconData icon = Icons.visibility_outlined;
    Color color = theme.textTheme.bodySmall?.color ?? Colors.grey;

    if (userType == 'job_seeker') {
      label = 'Job Seeker';
      icon = Icons.work_outline;
      color = theme.primaryColor;
    } else if (userType == 'employer') {
      label = 'Employer';
      icon = Icons.person_add_outlined;
      color = theme.colorScheme.secondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
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

  Widget _buildReviewSection(BuildContext context, AsyncValue<List<Map<String, dynamic>>> reviewsAsync) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reviews',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.textTheme.titleLarge?.color,
            ),
          ),
          const SizedBox(height: 12),
          reviewsAsync.when(
            data: (reviews) {
              if (reviews.isEmpty) {
                return Text(
                  'No reviews yet. Keep delivering great work to earn your first review.',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                );
              }
              return Column(
                children: reviews.take(3).map((r) => _buildReviewTile(context, r)).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, __) => Text(
              'Failed to load reviews: $err',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewTile(BuildContext context, Map<String, dynamic> review) {
    final theme = Theme.of(context);
    final rating = review['rating']?.toString() ?? '0';
    final comment = review['comment']?.toString() ?? 'No comment provided.';
    final createdAt = review['created_at'] != null
        ? DateTime.tryParse(review['created_at'].toString())
        : null;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.star, size: 16, color: theme.primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    rating,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleMedium?.color,
                    ),
                  ),
                ],
              ),
              if (createdAt != null)
                Text(
                  '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodySmall?.color),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
          ),
        ],
      ),
    );
  }
}
