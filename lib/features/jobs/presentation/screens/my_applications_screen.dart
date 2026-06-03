import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/job_application.dart';
import '../providers/job_applications_provider.dart';
import 'package:intl/intl.dart';

class MyApplicationsScreen extends ConsumerWidget {
  const MyApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final applicationsAsync = ref.watch(myApplicationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('My Applications'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myApplicationsProvider);
          return ref.read(myApplicationsProvider.future);
        },
        child: applicationsAsync.when(
          data: (applications) => applications.isEmpty
              ? SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    alignment: Alignment.center,
                    child: const Text(
                      'You haven\'t applied for any jobs yet.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final application = applications[index];
                    return _ApplicationTile(application: application);
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }
}

class _ApplicationTile extends ConsumerWidget {

  const _ApplicationTile({
    required this.application,
  });
  final JobApplication application;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('MMM dd, yyyy').format(application.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Job Application',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              _buildStatusBadge(application.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            application.coverLetter ?? 'No cover letter provided.',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          if (application.bidAmount != null)
            Text(
              'Bid: R${application.bidAmount!.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            'Applied on $dateStr',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          if (application.status == ApplicationStatus.pending) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _handleCancel(context, ref),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: const Text('Cancel Interest'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Interest?'),
        content: const Text('Are you sure you want to withdraw your interest for this job?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(jobApplicationNotifierProvider.notifier).withdrawApplication(
              applicationId: application.id,
              jobId: application.jobId,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Interest withdrawn successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to withdraw interest: $e')),
          );
        }
      }
    }
  }

  Widget _buildStatusBadge(ApplicationStatus status) {
    Color color;
    switch (status) {
      case ApplicationStatus.pending:
        color = Colors.orange;
        break;
      case ApplicationStatus.accepted:
        color = Colors.green;
        break;
      case ApplicationStatus.rejected:
        color = Colors.red;
        break;
      case ApplicationStatus.withdrawn:
        color = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
