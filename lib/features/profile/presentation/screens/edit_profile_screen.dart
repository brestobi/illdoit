import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../../../../core/repositories/location_repository.dart';
import '../../../../core/utils/validators.dart';
import '../providers/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _displayNameController;
  late TextEditingController _bioController;
  String? _selectedProvince;
  late TextEditingController _skillsController;
  bool _isLoading = false;
  File? _imageFile;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).valueOrNull;
    _displayNameController = TextEditingController(text: profile?.displayName ?? '');
    _bioController = TextEditingController(text: profile?.bio ?? '');
    _selectedProvince = profile?.location;
    _skillsController = TextEditingController(text: profile?.skills.join(', ') ?? '');
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userRepository = ref.read(userRepositoryProvider);

      // Upload image if selected
      if (_imageFile != null) {
        final bytes = await _imageFile!.readAsBytes();
        await userRepository.uploadAvatar(bytes: bytes);
      }

      // Update other profile data
      await userRepository.updateUserProfile(data: {
        'display_name': _displayNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'location': _selectedProvince,
        'skills': _skillsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
      });

      // Refresh profile provider
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);
    final provincesAsync = ref.watch(provincesProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) return const Center(child: Text('Profile not found'));
          
          // Initialize controllers if they are empty and profile is available
          if (_displayNameController.text.isEmpty && profile.displayName.isNotEmpty) {
            _displayNameController.text = profile.displayName;
            _bioController.text = profile.bio ?? '';
            _selectedProvince ??= profile.location;
            _skillsController.text = profile.skills.join(', ');
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar Picker
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: AppColors.surface,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (profile.avatarUrl != null
                                  ? CachedNetworkImageProvider(profile.avatarUrl!) as ImageProvider
                                  : null),
                          child: _imageFile == null && profile.avatarUrl == null
                              ? const Icon(Icons.person, size: 60, color: AppColors.textSecondary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 20,
                              color: AppColors.darkBg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Display Name
                  TextFormField(
                    controller: _displayNameController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                    ),
                    validator: (value) => Validators.required(value, 'Display name'),
                  ),
                  const SizedBox(height: 20),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    maxLines: 4,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Bio',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Location
                  provincesAsync.when(
                    data: (provinces) => DropdownButtonFormField<String>(
                      value: _selectedProvince != null && provinces.contains(_selectedProvince) 
                          ? _selectedProvince 
                          : null,
                      style: const TextStyle(color: AppColors.textPrimary),
                      dropdownColor: AppColors.surface,
                      decoration: const InputDecoration(
                        labelText: 'Location (Province)',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: provinces.map((String province) => DropdownMenuItem<String>(
                          value: province,
                          child: Text(province),
                        )).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedProvince = newValue;
                        });
                      },
                      validator: (value) => Validators.required(value, 'Province'),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, __) => Text('Error loading provinces: $e', style: const TextStyle(color: Colors.red)),
                  ),
                  const SizedBox(height: 20),

                  // Skills
                  TextFormField(
                    controller: _skillsController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Skills (comma separated)',
                      prefixIcon: Icon(Icons.bolt_outlined),
                      hintText: 'e.g. Design, Flutter, Tutoring',
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}
