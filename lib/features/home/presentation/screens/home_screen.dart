import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/repositories/category_repository.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../core/widgets/walking_worker_loader.dart';
import '../../../../core/widgets/app_animations.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../explore/presentation/providers/explore_provider.dart';
import '../../../notifications/presentation/providers/notification_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendingServicesAsync = ref.watch(trendingServicesProvider);
    final recentJobsAsync = ref.watch(recentJobsProvider);
    final recommendedWorkersAsync = ref.watch(recommendedWorkersProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final currentUser = ref.watch(supabaseServiceProvider).currentUser;
    final userName = currentUser?.userMetadata?['full_name'] ?? 'Hustler';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(trendingServicesProvider);
          ref.invalidate(recentJobsProvider);
          ref.invalidate(recommendedWorkersProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Custom App Bar
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: true,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              elevation: 0,
              centerTitle: false,
              leading: const Padding(
                padding: EdgeInsets.only(left: 16, top: 8, bottom: 8),
                child: AppLogo(size: 28),
              ),
              title: Text(
                'I\'ll Do It',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
              actions: [
                ScaleOnTap(
                  onTap: () => context.push(AppRoutes.wallet),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.wallet_outlined, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Wallet',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final unreadCount = ref.watch(unreadNotificationCountProvider);
                    return Badge(
                      label: Text('$unreadCount'),
                      isLabelVisible: unreadCount > 0,
                      backgroundColor: AppColors.primary,
                      textColor: AppColors.darkBg,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_none_rounded),
                        onPressed: () => context.push(AppRoutes.notifications),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Welcome & Search
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $userName 👋',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'What do you need help with today?',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 24),
                        
                        // Search Bar
                        ScaleOnTap(
                          onTap: () => context.go(AppRoutes.explore),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                              boxShadow: isDark ? [] : [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded, color: AppColors.primary),
                                const SizedBox(width: 12),
                                Text(
                                  'Search for "Logo Design", "Tutor"...',
                                  style: TextStyle(
                                    color: Theme.of(context).textTheme.bodySmall?.color,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Categories Horizontal
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(context, 'Explore Categories', null),
                        const SizedBox(height: 16),
                        categoriesAsync.when(
                          data: (categories) => SizedBox(
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length > 10 ? 10 : categories.length, // Limit home screen to top 10
                              clipBehavior: Clip.none,
                              itemBuilder: (context, index) {
                                final cat = categories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _buildCategoryItem(
                                    context,
                                    cat.name,
                                    CategoryUtils.getIconForCategory(cat.name),
                                    ref,
                                  ),
                                );
                              },
                            ),
                          ),
                          loading: () => const SizedBox(
                            height: 90,
                            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Conditional Verification
                  Consumer(
                    builder: (context, ref, child) {
                      final profile = ref.watch(profileProvider).valueOrNull;
                      if (profile == null || profile.isVerified) return const SizedBox.shrink();
                      
                      return FadeInAnimation(
                        delay: const Duration(milliseconds: 300),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.2),
                                AppColors.primary.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 32),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Trust is Everything',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Verify your ID to unlock premium gigs.',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              ScaleOnTap(
                                onTap: () => context.push(AppRoutes.verificationCenter),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Verify',
                                    style: TextStyle(color: AppColors.darkBg, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  // Trending Services Carousel
                  _buildSectionHeader(context, 'Trending Services', () => context.go(AppRoutes.explore)),
                  const SizedBox(height: 16),
                  trendingServicesAsync.when(
                    data: (services) => services.isEmpty
                        ? _buildEmptyState(context, 'No services yet')
                        : SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: services.length,
                              clipBehavior: Clip.none,
                              itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: _buildServiceCarouselCard(context, services[index]),
                                ),
                            ),
                          ),
                    loading: () => const Center(child: WalkingWorkerLoader(size: 30)),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 32),

                  // Recent Jobs List
                  _buildSectionHeader(context, 'Recent Jobs', () => context.go(AppRoutes.jobs)),
                  const SizedBox(height: 16),
                  recentJobsAsync.when(
                    data: (jobs) => jobs.isEmpty
                        ? _buildEmptyState(context, 'No jobs available')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: jobs.length > 3 ? 3 : jobs.length,
                            itemBuilder: (context, index) => _buildJobListItem(context, jobs[index]),
                          ),
                    loading: () => const Center(child: WalkingWorkerLoader(size: 30)),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 32),

                  // Quick Action Banner
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 500),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.darkBg == Theme.of(context).scaffoldBackgroundColor 
                            ? AppColors.surface 
                            : AppColors.darkBg,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Need something specific?',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Post a job and let the hustlers come to you.',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ScaleOnTap(
                            onTap: () => context.push(AppRoutes.createJob),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Text(
                                'Post a Job Now',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.darkBg),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Recommended Workers
                  _buildSectionHeader(context, 'Top Hustlers', () => context.go(AppRoutes.explore)),
                  const SizedBox(height: 16),
                  recommendedWorkersAsync.when(
                    data: (workers) => workers.isEmpty
                        ? _buildEmptyState(context, 'No workers found')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: workers.length > 5 ? 5 : workers.length,
                            itemBuilder: (context, index) => _buildWorkerListItem(context, workers[index]),
                          ),
                    loading: () => const Center(child: WalkingWorkerLoader(size: 30)),
                    error: (err, _) => Text('Error: $err'),
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, VoidCallback? onSeeAll) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: const Row(
              children: [
                Text('See All', style: TextStyle(fontWeight: FontWeight.bold)),
                Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
      ],
    );

  Widget _buildCategoryItem(BuildContext context, String name, IconData icon, WidgetRef ref) => ScaleOnTap(
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).state = name;
        context.go(AppRoutes.explore);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );

  Widget _buildServiceCarouselCard(BuildContext context, Service service) => ScaleOnTap(
      onTap: () => context.push(AppRoutes.serviceDetail.replaceFirst(':id', service.id)),
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: service.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.images.first,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      )
                    : Container(color: AppColors.primary.withOpacity(0.1), child: const Icon(Icons.image_outlined)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                          const SizedBox(width: 4),
                          Text('${service.rating}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Text(
                        'R${service.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildJobListItem(BuildContext context, Job job) => ScaleOnTap(
      onTap: () => context.push(AppRoutes.jobDetail.replaceFirst(':id', job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: R${job.budget.toStringAsFixed(0)} • ${job.category}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Bid',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildWorkerListItem(BuildContext context, User worker) => ScaleOnTap(
      onTap: () => context.push(AppRoutes.publicProfile.replaceFirst(':id', worker.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: worker.avatarUrl != null ? CachedNetworkImageProvider(worker.avatarUrl!) : null,
              child: worker.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(worker.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (worker.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  Text(
                    worker.skills.take(2).join(', '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 4),
                Text(worker.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );

  Widget _buildEmptyState(BuildContext context, String message) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(child: Text(message, style: Theme.of(context).textTheme.bodySmall)),
    );
}
