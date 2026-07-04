import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/job.dart';
import '../models/job_application.dart';
import '../models/job_milestone.dart';
import '../services/supabase_service.dart';
import '../errors/app_exceptions.dart';
import 'abstract_repositories.dart';

/// Concrete implementation of JobRepository using Supabase
class JobRepositoryImpl implements JobRepository {

  JobRepositoryImpl(this._supabaseService);
  final SupabaseService _supabaseService;

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

  /// Delete all open jobs whose deadline has passed.
  Future<int> cleanupExpiredJobs() async {
    try {
      final now = DateTime.now().toIso8601String();
      // Fetch expired open jobs
      final expired = await _supabaseService.client
          .from('jobs')
          .select('id')
          .eq('status', 'open')
          .lt('deadline', now);
      final ids = (expired as List).map((e) => (e as Map)['id'] as String).toList();
      // Delete each expired job (cascades to applications)
      for (final id in ids) {
        await _supabaseService.delete(table: 'jobs', id: id);
      }
      return ids.length;
    } catch (_) {
      return 0; // Non-critical — don't block fetching
    }
  }

  @override
  Future<List<Job>> getJobs({String? status, String? category, String? location}) async {
    try {
      // Cleanup expired open jobs before fetching
      await cleanupExpiredJobs();

      if (status == 'applied') {
        final currentUser = _supabaseService.currentUser;
        if (currentUser == null) throw AuthenticationException('No user logged in');
        
        // Fetch applications
        final applications = await _supabaseService.query(
          table: 'job_applications',
          filters: {'applicant_id': currentUser.id},
        );
        
        if (applications.isEmpty) return [];
        
        final jobIds = applications.map((app) => app['job_id'] as String).toList();
        
        // Fetch jobs (exclude completed — those go in the completed tab)
        final results = await _supabaseService.query(
          table: 'jobs',
          filters: {'id': jobIds, 'status': ['open', 'in_progress']},
        );
        return results.map(Job.fromJson).toList();
      }

      final filters = <String, dynamic>{};
      if (status != null) filters['status'] = status;
      if (category != null) filters['category'] = category;
      if (location != null) filters['location'] = location;

      // For open jobs, also filter out expired ones at query level
      var results = await _supabaseService.client
          .from('jobs')
          .select();

      filters.forEach((key, value) {
        if (value is List) {
          results = results.filter(key, 'in', value);
        } else {
          results = results.eq(key, value);
        }
      });

      // Exclude open jobs past deadline
      if (status == 'open') {
        results = results.gte('deadline', DateTime.now().toIso8601String());
      }

      final data = await results;
      return (data as List).map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      return results.map(Job.fromJson).toList();
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
      // Clean up related records first (applications, milestones)
      final apps = await _supabaseService.query(
        table: 'job_applications',
        filters: {'job_id': jobId},
      );
      for (final app in apps) {
        await _supabaseService.delete(table: 'job_applications', id: app['id'] as String);
      }

      final milestones = await _supabaseService.query(
        table: 'job_milestones',
        filters: {'job_id': jobId},
      );
      for (final m in milestones) {
        await _supabaseService.delete(table: 'job_milestones', id: m['id'] as String);
      }

      // Delete the job itself
      await _supabaseService.delete(table: 'jobs', id: jobId);
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
      
      return results.map(Job.fromJson).toList();
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
      return results.map(Job.fromJson).toList();
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
      return results.map(JobApplication.fromJson).toList();
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
      return results.map(JobApplication.fromJson).toList();
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
        // 1. Get the application to find the job_id
        final apps = await _supabaseService.query(
          table: 'job_applications',
          filters: {'id': applicationId},
        );
        if (apps.isEmpty) throw ServerException('Application not found');
        final jobId = apps.first['job_id'] as String;

        // 2. Use atomic RPC for hiring process
        await _supabaseService.client.rpc(
          'accept_job_escrow',
          params: {'p_application_id': applicationId},
        );

        // 3. Lock the job: set to in_progress (prevents new applications)
        await _supabaseService.update(
          table: 'jobs',
          id: jobId,
          data: {
            'status': 'in_progress',
            'updated_at': DateTime.now().toIso8601String(),
          },
        );

        // 4. Reject all other pending applications for this job
        final otherApps = await _supabaseService.query(
          table: 'job_applications',
          filters: {'job_id': jobId, 'status': 'pending'},
        );
        for (final app in otherApps) {
          await _supabaseService.update(
            table: 'job_applications',
            id: app['id'] as String,
            data: {
              'status': 'rejected',
              'updated_at': DateTime.now().toIso8601String(),
            },
          );
        }
      } else {
        // Just update application status
        await _supabaseService.client
            .from('job_applications')
            .update({
              'status': status.name,
              'updated_at': DateTime.now().toIso8601String()
            })
            .eq('id', applicationId);
      }
    } catch (e) {
      throw ServerException('Failed to update application status: $e');
    }
  }

  @override
  Future<List<Job>> getNearbyJobs({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      final results = await _supabaseService.client.rpc(
        'get_nearby_jobs',
        params: {
          'user_lat': lat,
          'user_lng': lng,
          'radius_km': radiusKm,
        },
      );
      return (results as List).map((e) => Job.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      throw ServerException('Failed to fetch nearby jobs: $e');
    }
  }

  @override
  Future<List<JobMilestone>> getJobMilestones({required String jobId}) async {
    try {
      final results = await _supabaseService.query(
        table: 'job_milestones',
        filters: {'job_id': jobId},
      );
      return results.map(JobMilestone.fromJson).toList();
    } catch (e) {
      throw ServerException('Failed to fetch milestones: $e');
    }
  }

  @override
  Future<JobMilestone> createJobMilestone({
    required String jobId,
    required String title,
    String? description,
  }) async {
    try {
      final response = await _supabaseService.insert(
        table: 'job_milestones',
        data: {
          'job_id': jobId,
          'title': title,
          'description': description,
          'status': 'pending',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
      return JobMilestone.fromJson(response);
    } catch (e) {
      throw ServerException('Failed to create milestone: $e');
    }
  }

  @override
  Future<void> updateJobMilestone({
    required String milestoneId,
    required String status,
  }) async {
    try {
      await _supabaseService.update(
        table: 'job_milestones',
        id: milestoneId,
        data: {
          'status': status,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      throw ServerException('Failed to update milestone: $e');
    }
  }

  @override
  Future<void> deleteJobMilestone({required String milestoneId}) async {
    try {
      await _supabaseService.delete(
        table: 'job_milestones',
        id: milestoneId,
      );
    } catch (e) {
      throw ServerException('Failed to delete milestone: $e');
    }
  }
}

/// Provider for JobRepository
final jobRepositoryProvider = Provider<JobRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return JobRepositoryImpl(supabaseService);
});
