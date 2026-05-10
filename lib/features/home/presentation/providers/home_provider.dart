import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/service.dart';
import '../../../../core/models/job.dart';
import '../../../../core/models/user.dart';
import '../../../../core/repositories/service_repository_impl.dart';
import '../../../../core/repositories/job_repository_impl.dart';
import '../../../../core/repositories/user_repository_impl.dart';

/// Provider for trending services
final trendingServicesProvider = FutureProvider<List<Service>>((ref) async {
  final serviceRepository = ref.watch(serviceRepositoryProvider);
  // For MVP, we just fetch the latest services as "trending"
  return serviceRepository.getServices();
});

/// Provider for recent jobs
final recentJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  // Fetch latest open jobs
  return jobRepository.getJobs(status: 'open');
});

/// Provider for recommended workers (job seekers)
final recommendedWorkersProvider = FutureProvider<List<User>>((ref) async {
  final userRepository = ref.watch(userRepositoryProvider);
  return userRepository.getUsers(userType: 'job_seeker', limit: 5);
});
