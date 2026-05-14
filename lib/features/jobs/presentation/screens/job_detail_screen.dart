import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/walking_worker_loader.dart';
import '../../../../core/models/job.dart';
import '../../../../core/extensions/extensions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../profile/presentation/providers/review_provider.dart';
import '../providers/jobs_provider.dart';
import '../providers/job_applications_provider.dart';

class JobDetailScreen extends ConsumerWidget {
  final String jobId;

  const JobDetailScreen({
    Key? key,
    required this.jobId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobAsync = ref.watch(jobProvider(jobId));

    return jobAsync.when(
      data: (job) {
        final deadlineStr = DateFormat('MMM dd, yyyy').format(job.deadline);
        final currentUserId = ref.watch(supabaseServiceProvider).currentUser?.id;
        final isOwner = currentUserId == job.clientId;
        final canApply = job.status == 'open' && !isOwner;
        final canReview = job.status != 'open' && currentUserId != null && !isOwner;

        return Scaffold(
          backgroundColor: AppColors.darkBg,
          appBar: AppBar(
            title: const Text('Job Details'),
            elevation: 0,
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _handleDeleteJob(context, ref, job.id),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Title and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        job.status.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Category
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
                  ),
                  child: Text(
                    job.category,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ),
                const SizedBox(height: 24),

                // Budget & Deadline & Location
                Row(
                  children: [
                    _buildInfoItem(Icons.payments_outlined, 'Budget', 'R${job.budget.toStringAsFixed(0)}'),
                    const SizedBox(width: 32),
                    _buildInfoItem(Icons.calendar_today_outlined, 'Deadline', deadlineStr),
                    if (job.location != null) ...[
                      const SizedBox(width: 32),
                      _buildInfoItem(Icons.location_on_outlined, 'Location', job.location!),
                    ],
                  ],
                ),
                const SizedBox(height: 32),

                // Client Info
                const Text(
                  'About the Client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                _ClientCard(userId: job.clientId),
                const SizedBox(height: 32),

                // Description
                const Text(
                  'Job Description',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  job.description,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Safety Tip for Physical Jobs
                if (job.jobType == 'physical') ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.security, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Safety Tip: For physical jobs, always meet in a public place and tell a friend your location.',
                            style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Images
                if (job.images.isNotEmpty) ...[
                  const Text(
                    'Job Images',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: job.images.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: job.images[index],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.surface,
                                child: const Center(child: CircularProgressIndicator()),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.surface,
                                child: const Icon(Icons.error_outline, color: Colors.white54),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 100),
              ],
            ),
          ),
          bottomSheet: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.borderColor)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.push(
                            AppRoutes.chat.replaceFirst(':id', job.clientId),
                            extra: 'Client',
                          );
                        },
                        child: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isOwner
                            ? () => context.push(
                                  AppRoutes.manageApplications.replaceFirst(':jobId', job.id),
                                )
                            : canApply
                                ? () async {
                                    final profile = ref.read(profileProvider).valueOrNull;
                                    if (job.jobType == 'physical' && (profile == null || !profile.isVerified)) {
                                      _showVerificationRequiredDialog(context);
                                      return;
                                    }

                                    final result = await showDialog<Map<String, dynamic>>(
                                      context: context,
                                      builder: (context) => _ApplyDialog(job: job),
                                    );

                                    if (result != null) {
                                      try {
                                        await ref.read(jobApplicationNotifierProvider.notifier).applyForJob(
                                              jobId: job.id,
                                              coverLetter: result['cover_letter'],
                                              bidAmount: result['bid_amount'],
                                            );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Your interest has been submitted!')),
                                          );
                                        }
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Failed to submit: $e')),
                                          );
                                        }
                                      }
                                    }
                                  }
                                : null,
                        child: Text(
                          isOwner
                              ? 'Manage Applications'
                              : canApply
                                  ? "I'll do it"
                                  : job.status == 'applied'
                                      ? 'Interest Sent'
                                      : 'Job ${job.status.capitalize()}',
                        ),
                      ),
                    ),
                  ],
                ),
                if (canReview) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () async {
                        await _showReviewDialog(context, ref, job.clientId);
                      },
                      child: const Text('Leave a review'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: WalkingWorkerLoader(label: 'Loading job details...')),
      ),
      error: (err, stack) => Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: Text('Error: $err')),
      ),
    );
  }

  Future<void> _handleDeleteJob(BuildContext context, WidgetRef ref, String jobId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Job?'),
        content: const Text('Are you sure you want to delete this job? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(jobNotifierProvider.notifier).deleteJob(jobId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Job deleted successfully.')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete job: $e')),
          );
        }
      }
    }
  }

  Future<void> _showReviewDialog(BuildContext context, WidgetRef ref, String targetUserId) async {
    final commentController = TextEditingController();
    var currentRating = 5;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Leave a Review'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(
                      5,
                      (index) {
                        final value = index + 1;
                        return IconButton(
                          icon: Icon(
                            value <= currentRating ? Icons.star : Icons.star_border,
                            color: AppColors.primary,
                          ),
                          onPressed: () {
                            setState(() {
                              currentRating = value;
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final comment = commentController.text.trim();
                try {
                  await ref.read(reviewNotifierProvider.notifier).createReview(
                        targetUserId: targetUserId,
                        rating: currentRating,
                        comment: comment,
                      );
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Review submitted successfully.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to submit review: $e')),
                    );
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showVerificationRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Verification Required', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Physical jobs require identity verification for safety and trust. Please complete your verification to apply.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(AppRoutes.verificationCenter);
            },
            child: const Text('Verify Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _ApplyDialog extends StatefulWidget {
  final Job job;

  const _ApplyDialog({Key? key, required this.job}) : super(key: key);

  @override
  State<_ApplyDialog> createState() => _ApplyDialogState();
}

class _ApplyDialogState extends State<_ApplyDialog> {
  late TextEditingController _coverLetterController;
  late TextEditingController _bidController;

  @override
  void initState() {
    super.initState();
    _coverLetterController = TextEditingController();
    _bidController = TextEditingController(text: widget.job.budget.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _coverLetterController.dispose();
    _bidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text("I'll do it", style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _bidController,
              decoration: const InputDecoration(
                labelText: 'Your Bid (R)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
              ),
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _coverLetterController,
              decoration: const InputDecoration(
                labelText: 'Cover Letter',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                hintText: 'Explain why you are the best fit for this job...',
                hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              maxLines: 5,
              style: const TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'bid_amount': double.tryParse(_bidController.text) ?? widget.job.budget,
              'cover_letter': _coverLetterController.text,
            });
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}

class _ClientCard extends ConsumerWidget {
  final String userId;

  const _ClientCard({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(userProvider(userId));
    final reviewsAsync = ref.watch(userReviewsProvider(userId));

    return clientAsync.when(
      data: (user) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        user.location ?? 'Unknown location',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        user.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (reviewsAsync.hasValue)
                        Text(
                          '${reviewsAsync.value!.length} reviews',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                context.push(AppRoutes.publicProfile.replaceFirst(':id', job.clientId));
              },
              child: const Text('View Profile'),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox(height: 100, child: Center(child: WalkingWorkerLoader(size: 30, label: 'Loading client...'))),
      error: (err, stack) => const Text('Error loading client'),
    );
  }
}
