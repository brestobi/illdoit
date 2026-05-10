import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class OnboardingStepsScreen extends ConsumerStatefulWidget {
  const OnboardingStepsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<OnboardingStepsScreen> createState() => _OnboardingStepsScreenState();
}

class _OnboardingStepsScreenState extends ConsumerState<OnboardingStepsScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Form data
  String _selectedRole = 'viewer'; // viewer, job_seeker, employer
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<String> _selectedSkills = [];

  final List<String> _availableSkills = [
    'Plumbing', 'Electrical', 'Carpentry', 'Cleaning', 
    'Gardening', 'Painting', 'Graphic Design', 'Web Development',
    'Writing', 'Tutoring', 'Handyman', 'Delivery'
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill data if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider).valueOrNull;
      if (profile != null) {
        setState(() {
          _selectedRole = profile.userType == 'viewer' ? 'viewer' : profile.userType;
          _bioController.text = profile.bio ?? '';
          _locationController.text = profile.location ?? '';
          _phoneController.text = profile.phone ?? '';
          _selectedSkills = List.from(profile.skills);
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // If viewer is selected, skip skills step
      if (_currentStep == 1 && _selectedRole == 'viewer') {
        _submitOnboarding();
        return;
      }
      
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitOnboarding() async {
    try {
      final repository = ref.read(userRepositoryProvider);
      await repository.updateUserProfile(data: {
        'user_type': _selectedRole,
        'bio': _bioController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'skills': _selectedSkills,
        'is_onboarding_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      // Refresh profile to update local state
      ref.invalidate(profileProvider);
      
      if (mounted) {
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Step ${_currentStep + 1} of $_totalSteps',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => context.go(AppRoutes.home),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentStep + 1) / _totalSteps,
                      backgroundColor: AppColors.surface,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),

            // Steps
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentStep = index;
                  });
                },
                children: [
                  _buildRoleSelectionStep(),
                  _buildBasicInfoStep(),
                  _buildSkillsStep(),
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back', style: TextStyle(color: AppColors.textPrimary)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1 || (_currentStep == 1 && _selectedRole == 'viewer')
                            ? 'Complete Profile'
                            : 'Next',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How do you want to use I\'ll Do It?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You can always change this later in your settings.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildRoleCard(
            id: 'viewer',
            title: 'Just Browsing',
            description: 'I want to explore services and see what\'s available.',
            icon: Icons.visibility_outlined,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            id: 'job_seeker',
            title: 'I want to Work',
            description: 'I want to offer my skills and find job opportunities.',
            icon: Icons.work_outline,
          ),
          const SizedBox(height: 16),
          _buildRoleCard(
            id: 'employer',
            title: 'I want to Hire',
            description: 'I want to post jobs and find skilled workers.',
            icon: Icons.person_add_outlined,
          ),
        ],
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.black : AppColors.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps other users get to know you better.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. +27 12 345 6789',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              hintText: 'e.g. Johannesburg, Gauteng',
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about your experience or what you\'re looking for...',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What are your skills?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select the skills you can offer to others.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _availableSkills.map((skill) {
              final isSelected = _selectedSkills.contains(skill);
              return FilterChip(
                label: Text(skill),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedSkills.add(skill);
                    } else {
                      _selectedSkills.remove(skill);
                    }
                  });
                },
                selectedColor: AppColors.primary,
                checkmarkColor: AppColors.black,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.black : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                backgroundColor: AppColors.surfaceAlt,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: const InputDecoration(
              hintText: 'Add other skills (separated by comma)',
              prefixIcon: Icon(Icons.add_circle_outline),
            ),
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                final newSkills = value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty);
                setState(() {
                  _selectedSkills.addAll(newSkills);
                });
              }
            },
          ),
        ],
      ),
    );
  }
}
