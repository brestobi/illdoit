import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/job.dart';
import '../../../../core/repositories/abstract_repositories.dart';
import '../../../../core/repositories/job_repository_impl.dart';

/// Provider for all open jobs
final openJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getJobs(status: 'open');
});

/// Provider for user's own posted jobs
final myJobsProvider = FutureProvider<List<Job>>((ref) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getMyJobs();
});

/// Provider for jobs by status
final jobsByStatusProvider = FutureProvider.family<List<Job>, String>((ref, status) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getJobs(status: status);
});

/// Provider for a single job by ID
final jobProvider = FutureProvider.family<Job, String>((ref, id) async {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return jobRepository.getJobById(jobId: id);
});

/// State for Job operations
class JobState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  JobState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  JobState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return JobState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// Notifier for job operations
class JobNotifier extends StateNotifier<JobState> {
  final JobRepository _jobRepository;
  final Ref _ref;

  JobNotifier(this._jobRepository, this._ref) : super(JobState());

  Future<void> createJob(Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _jobRepository.createJob(data: data);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myJobsProvider);
      _ref.invalidate(openJobsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<String?> uploadImage(List<int> bytes) async {
    try {
      return await _jobRepository.uploadJobImage(bytes: bytes);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  Future<void> updateJob(String id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _jobRepository.updateJob(jobId: id, data: data);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myJobsProvider);
      _ref.invalidate(openJobsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> deleteJob(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _jobRepository.deleteJob(jobId: id);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(myJobsProvider);
      _ref.invalidate(openJobsProvider);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> applyForJob(String jobId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await _jobRepository.applyForJob(jobId: jobId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      _ref.invalidate(jobProvider(jobId));
      _ref.invalidate(openJobsProvider);
      _ref.invalidate(jobsByStatusProvider('applied'));
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = JobState();
  }
}

/// Provider for JobNotifier
final jobNotifierProvider = StateNotifierProvider<JobNotifier, JobState>((ref) {
  final jobRepository = ref.watch(jobRepositoryProvider);
  return JobNotifier(jobRepository, ref);
});
