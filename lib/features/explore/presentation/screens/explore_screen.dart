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
import '../../../../core/widgets/app_animations.dart';
import '../../../../core/repositories/location_repository.dart';
import '../../../../core/repositories/category_repository.dart';
import '../../../../core/utils/category_utils.dart';
import '../../../../core/utils/marker_utils.dart';
import '../providers/explore_provider.dart';
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
  BitmapDescriptor? _logoMarker;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _loadMarker();
  }

  Future<void> _loadMarker() async {
    _logoMarker = await createLogoMarker(size: 60);
    if (mounted) setState(() {});
  }

  Future<void> _determinePosition() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;
    try {
      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      }
    } catch (_) {
      // Location unavailable — map will use default
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
    final resultsAsync = searchType == SearchType.services
        ? ref.watch(exploreServicesProvider)
        : (searchType == SearchType.jobs
            ? ref.watch(exploreJobsProvider)
            : ref.watch(exploreUsersProvider));
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedLocation = ref.watch(selectedLocationProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Explore'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showMap ? Icons.list_rounded : Icons.map_outlined),
            tooltip: _showMap ? 'Show List' : 'Show Map',
            onPressed: () => setState(() => _showMap = !_showMap),
          ),
        ],
      ),
      body: _showMap
          ? _buildMapView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 100),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            ref.read(searchQueryProvider.notifier).state = value,
                        decoration: InputDecoration(
                          hintText: 'Search services, jobs, or people...',
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, color: AppColors.textTertiary),
                                  onPressed: () {
                                    _searchController.clear();
                                    ref.read(searchQueryProvider.notifier).state = '';
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Search Type Toggle
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 200),
                    child: Row(
                      children: [
                        _buildTypeChip(SearchType.services, 'Services'),
                        const SizedBox(width: 8),
                        _buildTypeChip(SearchType.jobs, 'Jobs'),
                        const SizedBox(width: 8),
                        _buildTypeChip(SearchType.users, 'Users'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Category Chips
                  categoriesAsync.when(
                    data: (categories) => FadeInAnimation(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedCategory != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Text(
                                    'Category: $selectedCategory',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => ref.read(selectedCategoryProvider.notifier).state = null,
                                    child: const Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: 36,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: categories.length > 12 ? 12 : categories.length,
                              itemBuilder: (context, index) {
                                final cat = categories[index];
                                final isSelected = selectedCategory == cat.name;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () {
                                      ref.read(selectedCategoryProvider.notifier).state =
                                          isSelected ? null : cat.name;
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Theme.of(context).colorScheme.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.primary
                                              : Theme.of(context).colorScheme.outline.withOpacity(0.4),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            CategoryUtils.getIconForCategory(cat.name),
                                            size: 14,
                                            color: isSelected ? AppColors.darkBg : AppColors.textTertiary,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            cat.name,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: isSelected
                                                  ? AppColors.darkBg
                                                  : Theme.of(context).textTheme.bodyMedium?.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Location Filter
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 350),
                    child: locationsAsync.when(
                      data: (locations) {
                        if (locations.isEmpty) return const SizedBox.shrink();
                        return Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textTertiary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String?>(
                                  value: selectedLocation,
                                  isExpanded: true,
                                  hint: Text(
                                    'Filter by location',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Theme.of(context).textTheme.bodyMedium?.color,
                                  ),
                                  dropdownColor: Theme.of(context).colorScheme.surface,
                                  icon: const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textTertiary),
                                  items: [
                                    if (selectedLocation != null)
                                      DropdownMenuItem<String?>(
                                        value: null,
                                        child: const Text('All locations', style: TextStyle(color: AppColors.textTertiary)),
                                      ),
                                    ...locations.map((loc) {
                                      final val = '${loc.name}, ${loc.province}';
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Text(val),
                                      );
                                    }),
                                  ],
                                  onChanged: (val) =>
                                      ref.read(selectedLocationProvider.notifier).state = val,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Results
                  FadeInAnimation(
                    delay: const Duration(milliseconds: 400),
                    child: resultsAsync.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return _buildEmptyState(searchType);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '${items.length} result${items.length == 1 ? '' : 's'} found',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                              ),
                            ),
                            ListView.builder(
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
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.only(top: 60),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                      error: (err, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32),
                          child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const MainBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildMapView() {
    return FutureBuilder<List<Job>>(
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const SizedBox(height: 12),
                Text('Could not load map: ${snapshot.error}',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          );
        }

        final jobs = snapshot.data ?? [];

        final icon = _logoMarker ?? BitmapDescriptor.defaultMarker;
        final markers = jobs.map((job) {
          return Marker(
            markerId: MarkerId(job.id),
            position: LatLng(job.latitude ?? -26.2041, job.longitude ?? 28.0473),
            icon: icon,
            infoWindow: InfoWindow(
              title: job.title,
              snippet: 'R${job.budget.toStringAsFixed(0)} • ${job.category}',
            ),
          );
        }).toSet();

        return AppMapWidget(
          markers: markers,
          initialPosition: _currentLocation,
        );
      },
    );
  }

  Widget _buildTypeChip(SearchType type, String label) {
    final isSelected = ref.watch(searchTypeProvider) == type;
    return GestureDetector(
      onTap: () => ref.read(searchTypeProvider.notifier).state = type,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.darkBg : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchType type) {
    String message;
    IconData icon;
    switch (type) {
      case SearchType.services:
        message = 'No services found.\nTry a different search or category.';
        icon = Icons.design_services_outlined;
        break;
      case SearchType.jobs:
        message = 'No jobs found.\nTry a different search or location.';
        icon = Icons.work_outline;
        break;
      case SearchType.users:
        message = 'Search for people by name or skill\nto find top hustlers.';
        icon = Icons.people_outline;
        break;
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(Service service) => GestureDetector(
        onTap: () => context.push(AppRoutes.serviceDetail.replaceFirst(':id', service.id)),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: service.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: service.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Center(
                              child: SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.image_outlined, color: AppColors.textTertiary, size: 24),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.design_services_outlined,
                              color: AppColors.textTertiary, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 3),
                        Text(
                          service.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'R${service.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
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
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: job.images.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: job.images.first,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.primary.withOpacity(0.1)),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.work_outline, color: AppColors.textTertiary, size: 24),
                          ),
                        )
                      : Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.work_outline, color: AppColors.textTertiary, size: 24),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${job.category}${job.location != null ? " • ${job.location}" : ""}',
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'R${job.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
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
            borderRadius: BorderRadius.circular(14),
            border:
                Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                backgroundImage:
                    user.avatarUrl != null ? CachedNetworkImageProvider(user.avatarUrl!) : null,
                child: user.avatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textTertiary)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.displayName,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.skills.isNotEmpty ? user.skills.take(3).join(', ') : 'No skills listed',
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
                      const Icon(Icons.star_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(
                        user.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
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
