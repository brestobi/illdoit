import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../providers/profile_provider.dart';

class ChangeRoleScreen extends ConsumerStatefulWidget {
  const ChangeRoleScreen({super.key});

  @override
  ConsumerState<ChangeRoleScreen> createState() => _ChangeRoleScreenState();
}

class _ChangeRoleScreenState extends ConsumerState<ChangeRoleScreen> {
  String _selectedRole = 'viewer';

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    if (profile != null) {
      _selectedRole = profile.userType;
    }
  }

  Future<void> _updateRole() async {
    try {
      await ref.read(userRepositoryProvider).updateUserProfile(data: {'user_type': _selectedRole});
      ref.invalidate(profileProvider);
      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Role updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update role. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change Account Role')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildRoleCard(
              id: 'viewer',
              title: 'Just Browsing',
              description: 'Explore services and view availability.',
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              id: 'job_seeker',
              title: 'I want to Work',
              description: 'Offer skills and find job opportunities.',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 16),
            _buildRoleCard(
              id: 'employer',
              title: 'I want to Hire',
              description: 'Post jobs and find skilled workers.',
              icon: Icons.person_add_outlined,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _updateRole,
              child: const Text('Update Role'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedRole == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = id),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderColor,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(description, style: const TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
