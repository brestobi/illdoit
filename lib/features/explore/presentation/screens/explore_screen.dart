import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/widgets/main_bottom_nav_bar.dart';
import '../../../../core/widgets/app_map_widget.dart';
import '../../../../core/repositories/location_repository.dart';
import '../../../../core/repositories/category_repository.dart';
import '../../../../core/utils/category_utils.dart';
import '../providers/explore_provider.dart';
import '../../../jobs/presentation/providers/jobs_provider.dart';
import '../../../../core/repositories/job_repository_impl.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showMap = false;
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    return permission != LocationPermission.deniedForever;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchType = ref.watch(searchTypeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final resultsAsync = searchType == SearchType.services
        ? ref.watch(exploreServicesProvider)
        : (searchType == SearchType.jobs
            ? ref.watch(exploreJobsProvider)
            : ref.watch(exploreUsersProvider));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list : Icons.map_outlined),
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _showMap
          ? FutureBuilder<List<Job>>(
              future: _currentLocation != null
                  ? ref.read(jobRepositoryProvider).getNearbyJobs(
                      lat: _currentLocation!.latitude,
                      lng: _currentLocation!.longitude,
                      radiusKm: 50,
                    )
                  : Future.value([]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  debugPrint('Nearby Jobs Error: ${snapshot.error}');
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final jobs = snapshot.data ?? [];
                debugPrint('Fetched ${jobs.length} nearby jobs. Current Location: $_currentLocation');
                
                final markers = jobs.map((job) {
                  return Marker(
                    markerId: MarkerId(job.id),
                    position: LatLng(job.latitude ?? -26.2041, job.longitude ?? 28.0473),
                    infoWindow: InfoWindow(title: job.title, snippet: 'R${job.budget.toStringAsFixed(0)}'),
                  );
                }).toSet();
                
                debugPrint('Created ${markers.length} markers.');

                return AppMapWidget(
                  markers: markers,
                  initialPosition: _currentLocation,
                );
              },
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ... (Search Bar, Toggle, Location Filter, Categories) ...
                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) =>
                          ref.read(searchQueryProvider.notifier).state = value,
                      decoration: InputDecoration(
                        hintText: 'Search services or jobs...',
                        prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                                onPressed: () {
                                  _searchController.clear();
                                  ref.read(searchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                      ),
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
                  
                  // Results
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
  // ... (Rest of the _build methods) ...

  Widget _buildTypeChip(SearchType type, String label) {
    final isSelected = ref.watch(searchTypeProvider) == type;
    return GestureDetector(
      onTap: () => ref.read(searchTypeProvider.notifier).state = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.darkBg : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, IconData icon, bool isSelected) => GestureDetector(
      onTap: () => ref.read(selectedCategoryProvider.notifier).state = name,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

  Widget _buildEmptyState() => Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              'No results found. Try a different search.',
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
      ),
    );

  Widget _buildServiceCard(Service service) => GestureDetector(
      onTap: () => context.push(AppRoutes.serviceDetail.replaceFirst(':id', service.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildJobCard(Job job) => GestureDetector(
      onTap: () => context.push(AppRoutes.jobDetail.replaceFirst(':id', job.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.2),
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
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${job.category}${job.location != null ? " • ${job.location}" : ""}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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

  Widget _buildUserCard(User user) => GestureDetector(
      onTap: () => context.push(AppRoutes.publicProfile.replaceFirst(':id', user.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.completedJobs} jobs',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
}
