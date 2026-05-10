import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/repositories/service_repository_impl.dart';
import '../../../../core/repositories/job_repository_impl.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// Search query state provider
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Selected category provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

/// Search type (Services, Jobs or Users)
enum SearchType { services, jobs, users }
final searchTypeProvider = StateProvider<SearchType>((ref) => SearchType.services);

/// Explore services results provider
final exploreServicesProvider = FutureProvider<List<Service>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final serviceRepository = ref.watch(serviceRepositoryProvider);

  if (query.isEmpty && category == null) {
    return serviceRepository.getServices();
  }

  if (query.isNotEmpty) {
    return serviceRepository.searchServices(query: query, category: category);
  }

  return serviceRepository.getServices(category: category);
});

/// Explore jobs results provider
final exploreJobsProvider = FutureProvider<List<Job>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(selectedCategoryProvider);
  final jobRepository = ref.watch(jobRepositoryProvider);

  if (query.isEmpty && category == null) {
    return jobRepository.getJobs();
  }

  if (query.isNotEmpty) {
    return jobRepository.searchJobs(query: query, category: category);
  }

  return jobRepository.getJobs(category: category);
});

/// Explore users results provider
final exploreUsersProvider = FutureProvider<List<User>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  if (query.isEmpty) {
    return [];
  }

  return userRepository.searchUsers(query: query);
});
