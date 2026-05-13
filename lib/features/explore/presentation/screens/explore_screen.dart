import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../providers/explore_provider.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Design', 'icon': Icons.palette_outlined},
    {'name': 'Development', 'icon': Icons.code},
    {'name': 'Marketing', 'icon': Icons.campaign_outlined},
    {'name': 'Writing', 'icon': Icons.edit_note},
    {'name': 'Video', 'icon': Icons.videocam_outlined},
    {'name': 'Music', 'icon': Icons.music_note_outlined},
    {'name': 'Photography', 'icon': Icons.camera_alt_outlined},
    {'name': 'Tutoring', 'icon': Icons.school_outlined},
    {'name': 'Support', 'icon': Icons.support_agent_outlined},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final resultsAsync = searchType == SearchType.services
        ? ref.watch(exploreServicesProvider)
        : (searchType == SearchType.jobs
            ? ref.watch(exploreJobsProvider)
            : ref.watch(exploreUsersProvider));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (value) =>
                  ref.read(searchQueryProvider.notifier).state = value,
              decoration: InputDecoration(
                hintText: 'Search services or jobs...',
                prefixIcon: const Icon(Icons.search),
                prefixIconColor: AppColors.textSecondary,
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(searchQueryProvider.notifier).state = '';
                        },
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 16),

            // Search Type Toggle
            Row(
              children: [
                _buildTypeChip(SearchType.services, 'Services'),
                const SizedBox(width: 8),
                _buildTypeChip(SearchType.jobs, 'Jobs'),
                const SizedBox(width: 8),
                _buildTypeChip(SearchType.users, 'Users'),
              ],
            ),
            const SizedBox(height: 16),

            // Location Filter (Only for Jobs)
            if (searchType == SearchType.jobs) ...[
              DropdownButtonFormField<String>(
                value: ref.watch(selectedLocationProvider),
                decoration: InputDecoration(
                  hintText: 'Filter by Location',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  suffixIcon: ref.watch(selectedLocationProvider) != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => ref.read(selectedLocationProvider.notifier).state = null,
                        )
                      : null,
                ),
                items: const [
                  DropdownMenuItem(value: 'Cape Town', child: Text('Cape Town')),
                  DropdownMenuItem(value: 'Johannesburg', child: Text('Johannesburg')),
                  DropdownMenuItem(value: 'Durban', child: Text('Durban')),
                  DropdownMenuItem(value: 'Pretoria', child: Text('Pretoria')),
                  DropdownMenuItem(value: 'Port Elizabeth', child: Text('Port Elizabeth')),
                ],
                onChanged: (value) => ref.read(selectedLocationProvider.notifier).state = value,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),
            ],
            
            // Categories
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (selectedCategory != null)
                  TextButton(
                    onPressed: () =>
                        ref.read(selectedCategoryProvider.notifier).state = null,
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.primary)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                return _buildCategoryCard(
                  cat['name'],
                  cat['icon'],
                  selectedCategory == cat['name'],
                );
              },
            ),
            const SizedBox(height: 24),

            // Results
            Text(
              '${searchType == SearchType.services ? 'Services' : (searchType == SearchType.jobs ? 'Jobs' : 'Users')} Results',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            resultsAsync.when(
              data: (items) => items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        if (item is Service) return _buildServiceCard(item);
                        if (item is Job) return _buildJobCard(item);
                        if (item is User) return _buildUserCard(item);
                        return const SizedBox.shrink();
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildTypeChip(SearchType type, String label) {
    final isSelected = ref.watch(searchTypeProvider) == type;
    return GestureDetector(
      onTap: () => ref.read(searchTypeProvider.notifier).state = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.darkBg : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(selectedCategoryProvider.notifier).state = name,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: AppColors.textSecondary),
            SizedBox(height: 16),
            Text(
              'No results found. Try a different search.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail.replaceFirst(':id', service.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: service.images.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: service.images.first,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error_outline, size: 20),
                      )
                    : const Icon(Icons.image_outlined, color: AppColors.darkBg),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R${service.price.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJobCard(Job job) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.jobDetail.replaceFirst(':id', job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.work_outline, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    job.category,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              'R${job.budget.toStringAsFixed(0)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(User user) {
    return GestureDetector(
      onTap: () => context.push(AppRoutes.publicProfile.replaceFirst(':id', user.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: AppColors.primary,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person, color: AppColors.darkBg)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.displayName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (user.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 14, color: AppColors.primary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.skills.isNotEmpty
                        ? user.skills.join(', ')
                        : 'No skills listed',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 14, color: AppColors.primary),
                    const SizedBox(width: 4),
                    Text(
                      user.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.completedJobs} jobs',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
