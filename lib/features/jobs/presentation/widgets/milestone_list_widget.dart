import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/job_milestone.dart';
import '../../../../core/repositories/job_repository_impl.dart';
import '../../../../core/constants/app_colors.dart';

class MilestoneListWidget extends ConsumerWidget {
  final String jobId;
  final bool isProvider;

  const MilestoneListWidget({
    super.key,
    required this.jobId,
    required this.isProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final milestonesAsync = ref.watch(jobMilestonesProvider(jobId));

    return milestonesAsync.when(
      data: (milestones) {
        if (milestones.isEmpty) {
          return const Center(child: Text('No milestones yet.'));
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: milestones.length,
          itemBuilder: (context, index) {
            final milestone = milestones[index];
            return _buildMilestoneTile(context, ref, milestone);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildMilestoneTile(BuildContext context, WidgetRef ref, JobMilestone milestone) {
    final isCompleted = milestone.status == 'completed';
    return ListTile(
      leading: Icon(
        isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompleted ? AppColors.primary : Colors.grey,
      ),
      title: Text(milestone.title, style: TextStyle(decoration: isCompleted ? TextDecoration.lineThrough : null)),
      subtitle: Text(milestone.description ?? ''),
      trailing: isProvider && !isCompleted
          ? IconButton(
              icon: const Icon(Icons.check_circle_outline),
              onPressed: () => _updateMilestone(ref, milestone.id),
            )
          : null,
    );
  }

  Future<void> _updateMilestone(WidgetRef ref, String milestoneId) async {
    await ref.read(jobRepositoryProvider).updateJobMilestone(milestoneId: milestoneId, status: 'completed');
    ref.invalidate(jobMilestonesProvider(jobId));
  }
}

final jobMilestonesProvider = FutureProvider.family<List<JobMilestone>, String>((ref, jobId) async {
  return ref.read(jobRepositoryProvider).getJobMilestones(jobId: jobId);
});
