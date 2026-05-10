import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/job_application.dart';
import '../../../../core/router/app_router.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../providers/job_applications_provider.dart';
import '../providers/jobs_provider.dart';

class ManageApplicationsScreen extends ConsumerWidget {
  final String jobId;

  const ManageApplicationsScreen({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(jobApplicationsProvider(jobId));
    final jobAsync = ref.watch(jobProvider(jobId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Manage Applications'),
        elevation: 0,
      ),
      body: jobAsync.when(
        data: (job) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Job Summary Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(bottom: BorderSide(color: AppColors.borderColor)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    job.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.payments_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Budget: R${job.budget.toStringAsFixed(0)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      const SizedBox(width: 24),
                      const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Deadline: ${DateFormat('MMM dd').format(job.deadline)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Applications List
            Expanded(
              child: applicationsAsync.when(
                data: (applications) {
                  if (applications.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment_late_outlined, size: 64, color: AppColors.textTertiary),
                          const SizedBox(height: 16),
                          Text(
                            'No applications yet.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: applications.length,
                    itemBuilder: (context, index) {
                      return _buildApplicationCard(context, ref, applications[index]);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildApplicationCard(BuildContext context, WidgetRef ref, JobApplication application) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Applicant Info Header
          _ApplicantHeader(userId: application.applicantId),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Bid Amount:',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    Text(
                      'R${application.bidAmount?.toStringAsFixed(0) ?? 'N/A'}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cover Letter:',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  application.coverLetter ?? 'No cover letter provided.',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 16),
                
                // Action Buttons
                if (application.status == 'pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _handleStatusUpdate(ref, application.id, ApplicationStatus.rejected),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleStatusUpdate(ref, application.id, ApplicationStatus.accepted),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Hire Now'),
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: application.status == 'accepted' 
                        ? AppColors.success.withOpacity(0.1) 
                        : AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        application.status.name.toUpperCase(),
                        style: TextStyle(
                          color: application.status == ApplicationStatus.accepted ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _handleStatusUpdate(WidgetRef ref, String id, ApplicationStatus status) async {
    await ref.read(jobApplicationNotifierProvider.notifier).updateStatus(
      applicationId: id,
      status: status,
    );
    // Refresh the list
    ref.invalidate(jobApplicationsProvider(jobId));
  }
}

class _ApplicantHeader extends ConsumerWidget {
  final String userId;

  const _ApplicantHeader({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider(userId));

    return userAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${user.rating.toStringAsFixed(1)} • ${user.completedJobs} jobs',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
              onPressed: () => context.push(
                AppRoutes.chat.replaceFirst(':id', userId),
                extra: user.displayName,
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
      error: (_, __) => const Text('Error loading applicant'),
    );
  }
}
