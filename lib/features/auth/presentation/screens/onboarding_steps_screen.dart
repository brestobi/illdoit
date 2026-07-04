import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../../../../core/repositories/skill_repository.dart';
import '../../../../core/repositories/location_repository.dart';
import '../../../../core/models/location.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class OnboardingStepsScreen extends ConsumerStatefulWidget {

  @override
  ConsumerState<OnboardingStepsScreen> createState() => _OnboardingStepsScreenState();
}

class _OnboardingStepsScreenState extends ConsumerState<OnboardingStepsScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Form data
  String _selectedRole = 'viewer'; // viewer, job_seeker, employer
  String _preferredJobType = 'both'; // digital, physical, both
  final TextEditingController _bioController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  List<String> _selectedSkills = [];
  bool _isAccountVisible = true;

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
        'preferred_job_type': _preferredJobType,
        'bio': _bioController.text,
        'location': _locationController.text,
        'phone': _phoneController.text,
        'skills': _selectedSkills,
        'is_onboarding_completed': true,
        'is_profile_public': _isAccountVisible,
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
    final skillsAsync = ref.watch(skillsProvider);
    final locationsAsync = ref.watch(locationsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.all(24),
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
                      const SizedBox(),
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
                  _buildJobPreferenceStep(),
                  _buildBasicInfoStep(locationsAsync),
                  _buildSkillsStep(skillsAsync),
                ],
              ),
            ),

            // Bottom Navigation
            Padding(
              padding: const EdgeInsets.all(24),
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

  Widget _buildRoleSelectionStep() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How do you want to use illdoit spaces?',
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

  Widget _buildJobPreferenceStep() => SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What kind of work interests you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This helps us show you the most relevant opportunities.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 32),
          _buildPreferenceCard(
            id: 'digital',
            title: 'Digital Jobs',
            description: 'Remote work, design, writing, development, etc.',
            icon: Icons.computer,
          ),
          const SizedBox(height: 16),
          _buildPreferenceCard(
            id: 'physical',
            title: 'Physical Jobs',
            description: 'On-site work, plumbing, cleaning, delivery, etc.',
            icon: Icons.hail,
          ),
          const SizedBox(height: 16),
          _buildPreferenceCard(
            id: 'both',
            title: 'Both',
            description: 'I\'m open to both digital and physical opportunities.',
            icon: Icons.all_inclusive,
          ),
        ],
      ),
    );

  Widget _buildPreferenceCard({
    required String id,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _preferredJobType == id;
    return GestureDetector(
      onTap: () => setState(() => _preferredJobType = id),
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
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep(AsyncValue<List<AppLocation>> locationsAsync) {
    const bioSuggestions = [
      'I am a skilled professional with experience in...',
      'I specialize in digital services including...',
      'I offer physical/on-site services such as...',
      'I\'m looking for opportunities in...',
      'I have X years of experience in...',
    ];

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

          // Phone Number with +27 prefix
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '12 345 6789',
              prefixText: '+27 ',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 20),

          // Location
          locationsAsync.when(
            data: (locations) => DropdownButtonFormField<String>(
              value: _locationController.text.isNotEmpty &&
                     locations.any((l) => '${l.name}, ${l.province}' == _locationController.text)
                  ? _locationController.text
                  : null,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
              dropdownColor: AppColors.surface,
              items: locations.map((loc) {
                final val = '${loc.name}, ${loc.province}';
                return DropdownMenuItem(
                  value: val,
                  child: Text(val, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _locationController.text = val);
              },
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Location',
                hintText: 'e.g. Johannesburg, Gauteng',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Bio
          TextField(
            controller: _bioController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio',
              hintText: 'Tell us about your experience or what you\'re looking for...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 12),

          // Bio suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: bioSuggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (_bioController.text.isEmpty) {
                      _bioController.text = suggestion;
                    } else {
                      _bioController.text = '${_bioController.text} $suggestion';
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Account Visibility
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_outlined, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account Visibility',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _isAccountVisible
                            ? 'Your profile is visible to other users'
                            : 'Your profile is hidden from other users',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _isAccountVisible,
                  activeColor: AppColors.primary,
                  onChanged: (value) => setState(() => _isAccountVisible = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsStep(AsyncValue<List<String>> skillsAsync) => SingleChildScrollView(
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
          skillsAsync.when(
            data: (skills) => Wrap(
              spacing: 12,
              runSpacing: 12,
              children: skills.map((skill) {
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
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, __) => Text('Error loading skills: $e', style: const TextStyle(color: Colors.red)),
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
