import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/job_application.dart';
import '../../../../core/repositories/abstract_repositories.dart';
import '../../../../core/repositories/job_repository_impl.dart';

/// Provider for applications to a specific job
final jobApplicationsProvider = FutureProvider.family<List<JobApplication>, String>((ref, jobId) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getJobApplications(jobId: jobId);
});

/// Provider for current user's job applications
final myApplicationsProvider = FutureProvider<List<JobApplication>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getMyApplications();
});

/// Notifier for job application actions
class JobApplicationNotifier extends StateNotifier<AsyncValue<void>> {
  final JobRepository _jobRepository;

  JobApplicationNotifier(this._jobRepository) : super(const AsyncValue.data(null));

  Future<void> applyForJob({
    required String jobId,
    String? coverLetter,
    double? bidAmount,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _jobRepository.applyForJob(
        jobId: jobId,
        coverLetter: coverLetter,
        bidAmount: bidAmount,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _jobRepository.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final jobApplicationNotifierProvider = StateNotifierProvider<JobApplicationNotifier, AsyncValue<void>>((ref) {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return JobApplicationNotifier(jobRepository);
});
