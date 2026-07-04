import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/repositories/service_repository_impl.dart';
import '../../../../core/repositories/job_repository_impl.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// Provider for trending services — fetches the 10 most recently created services
final trendingServicesProvider = FutureProvider<List<Service>>((ref) async {
  final serviceRepository = ref.watch(serviceRepositoryProvider);
  return serviceRepository.getServices(sortBy: 'created_at');
});

/// Provider for recent open jobs — fetches the 5 most recently created open jobs
final recentJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getJobs(status: 'open');
});

/// Provider for recommended workers (job seekers sorted by rating, highest first)
final recommendedWorkersProvider = FutureProvider<List<User>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  final workers = await userRepository.getUsers(userType: 'job_seeker');
  workers.sort((a, b) => b.rating.compareTo(a.rating));
  return workers.take(5).toList();
});
