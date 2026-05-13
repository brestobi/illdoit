import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/job_application.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of JobRepository using Supabase
class JobRepositoryImpl implements JobRepository {
  final SupabaseService _supabaseService;

  JobRepositoryImpl(this._supabaseService);

  @override
  Future<Job> createJob({required Map<String, dynamic> data}) async {
    try {
      // Ensure user profile exists to avoid FK violation (client_id references users)
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final profile = await _supabaseService.query(
          table: 'users',
          filters: {'id': currentUser.id},
        );
        if (profile.isEmpty) {
          await _supabaseService.insert(
            table: 'users',
            data: {
              'id': currentUser.id,
              'email': currentUser.email,
              'display_name': currentUser.userMetadata?['full_name'] ?? currentUser.email?.split('@').first ?? 'User',
            },
          );
        }
      }

      final response = await _supabaseService.insert(
        table: 'jobs',
        data: data,
      );
      return Job.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create job: $e');
    }
  }

  @override
  Future<String> uploadJobImage({required List<int> bytes}) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final fileName = 'job_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '${currentUser.id}/$fileName';
      
      return await _supabaseService.uploadFile(
        bucket: 'job-images',
        path: path,
        bytes: bytes,
      );
    } catch (e) {
      if (e is ServerException || e is AuthenticationException) rethrow;
      throw ServerException('Failed to upload job image: $e');
    }
  }

  @override
  Future<List<Job>> getJobs({String? status, String? category, String? location}) async {
    try {
      final filters = <String, dynamic>{};
      if (status != null) filters['status'] = status;
      if (category != null) filters['category'] = category;
      if (location != null) filters['location'] = location;
      
      final results = await _supabaseService.query(
        table: 'jobs',
        filters: filters.isNotEmpty ? filters : null,
      );
      return results.map((e) => Job.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch jobs: $e');
    }
  }

  @override
  Future<Job> getJobById({required String jobId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'jobs',
        filters: {'id': jobId},
      );

      if (results.isEmpty) {
        throw ServerException('Job not found');
      }

      return Job.fromJson(results.first);
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to fetch job: $e');
    }
  }

  @override
  Future<void> updateJob({
    required String jobId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _supabaseService.update(
        table: 'jobs',
        id: jobId,
        data: data,
      );
    } catch (e) {
      throw ServerException('Failed to update job: $e');
    }
  }

  @override
  Future<void> deleteJob({required String jobId}) async {
    try {
      await _supabaseService.delete(
        table: 'jobs',
        id: jobId,
      );
    } catch (e) {
      throw ServerException('Failed to delete job: $e');
    }
  }

  @override
  Future<List<Job>> searchJobs({
    required String query,
    String? category,
    String? location,
  }) async {
    try {
      final filters = <String, dynamic>{};
      if (category != null) filters['category'] = category;
      if (location != null) filters['location'] = location;

      final results = await _supabaseService.query(
        table: 'jobs',
        filters: filters.isNotEmpty ? filters : null,
        searchFilters: query.isNotEmpty ? {'title': query} : null,
      );
      
      return results.map((e) => Job.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Search failed: $e');
    }
  }

  @override
  Future<List<Job>> getMyJobs() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      throw AuthenticationException('No user logged in');
    }

    try {
      final results = await _supabaseService.query(
        table: 'jobs',
        filters: {'client_id': currentUser.id},
      );
      return results.map((e) => Job.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch your jobs: $e');
    }
  }

  @override
  Future<JobApplication> applyForJob({
    required String jobId,
    String? coverLetter,
    double? bidAmount,
  }) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final response = await _supabaseService.insert(
        table: 'job_applications',
        data: {
          'job_id': jobId,
          'applicant_id': currentUser.id,
          'cover_letter': coverLetter,
          'bid_amount': bidAmount,
          'status': 'pending',
        },
      );
      return JobApplication.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to apply for job: $e');
    }
  }

  @override
  Future<List<JobApplication>> getJobApplications({required String jobId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'job_applications',
        filters: {'job_id': jobId},
      );
      return results.map((e) => JobApplication.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch applications: $e');
    }
  }

  @override
  Future<List<JobApplication>> getMyApplications() async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) throw AuthenticationException('No user logged in');

    try {
      final results = await _supabaseService.query(
        table: 'job_applications',
        filters: {'applicant_id': currentUser.id},
      );
      return results.map((e) => JobApplication.fromJson(e)).toList();
    } catch (e) {
      throw ServerException('Failed to fetch your applications: $e');
    }
  }

  @override
  Future<void> updateApplicationStatus({
    required String applicationId,
    required ApplicationStatus status,
  }) async {
    try {
      if (status == ApplicationStatus.accepted) {
        // 1. Get Application details
        final appResults = await _supabaseService.query(
          table: 'job_applications',
          filters: {'id': applicationId},
        );
        if (appResults.isEmpty) throw ServerException('Application not found');
        final app = JobApplication.fromJson(appResults.first);

        // 2. Get Job details
        final jobResults = await _supabaseService.query(
          table: 'jobs',
          filters: {'id': app.jobId},
        );
        if (jobResults.isEmpty) throw ServerException('Job not found');
        final job = Job.fromJson(jobResults.first);

        // Check if job is already assigned or completed
        if (job.status != 'open') {
          throw ServerException('This job is already in progress or has been completed.');
        }

        // 3. Check client balance (Simplified for MVP, using TransactionRepository logic would be better but keeping it here for speed)
        // In a real app, this should be a database-side RPC or transaction
        final bidAmount = app.bidAmount ?? job.budget;
        
        // Let's at least check the 'balance' column we added to users
        final clientResults = await _supabaseService.query(
          table: 'users',
          filters: {'id': job.clientId},
        );
        if (clientResults.isEmpty) throw ServerException('Client not found');
        final clientBalance = (clientResults.first['balance'] as num?)?.toDouble() ?? 0.0;

        if (clientBalance < bidAmount) {
          throw ServerException('Insufficient funds in wallet to hire. Please "Cash In" to top up your wallet.');
        }

        // 4. Create an Order for the job
        final orderResponse = await _supabaseService.insert(
          table: 'orders',
          data: {
            'buyer_id': job.clientId,
            'seller_id': app.applicantId,
            'job_id': job.id,
            'amount': app.bidAmount ?? job.budget,
            'status': 'in_progress',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );
        final orderId = orderResponse['id'];

        // 4. Create Escrow Transaction
        await _supabaseService.insert(
          table: 'transactions',
          data: {
            'sender_id': job.clientId,
            'receiver_id': app.applicantId,
            'amount': app.bidAmount ?? job.budget,
            'type': 'escrow',
            'status': 'pending',
            'order_id': orderId,
            'reference': 'Escrow for job: ${job.title}',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        // 5. Update Job status to in_progress
        await _supabaseService.update(
          table: 'jobs',
          id: job.id,
          data: {'status': 'in_progress', 'updated_at': DateTime.now().toIso8601String()},
        );
      }

      await _supabaseService.client
          .from('job_applications')
          .update({
            'status': status.name, 
            'updated_at': DateTime.now().toIso8601String()
          })
          .eq('id', applicationId);
    } catch (e) {
      throw ServerException('Failed to update application status: $e');
    }
  }
}

/// Provider for JobRepository
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return JobRepositoryImpl(supabaseService);
});
