import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/repositories/user_repository_impl.dart';
import '../providers/profile_provider.dart';

class IdVerificationScreen extends ConsumerStatefulWidget {
  const IdVerificationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends ConsumerState<IdVerificationScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  
  String? _selectedIdType;
  File? _idFrontFile;
  File? _idBackFile;
  File? _selfieFile;
  bool _isLoading = false;

  final List<String> _idTypes = [
    'South African ID Smart Card',
    'South African ID Book (Green)',
    'Passport',
    'Driver\'s License',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(String type) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: type == 'selfie' ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        if (type == 'front') _idFrontFile = File(pickedFile.path);
        if (type == 'back') _idBackFile = File(pickedFile.path);
        if (type == 'selfie') _selfieFile = File(pickedFile.path);
      });
    }
  }

  void _nextPage() {
    if (_currentStep == 0 && _selectedIdType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an ID type')),
      );
      return;
    }
    
    if (_currentStep == 1 && _idFrontFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the front of your ID')),
      );
      return;
    }

    if (_currentStep == 2 && _selectedIdType == 'South African ID Smart Card' && _idBackFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload the back of your Smart Card')),
      );
      return;
    }

    if (_currentStep < _totalSteps - 1) {
      // Skip back image step if not a Smart Card
      if (_currentStep == 1 && _selectedIdType != 'South African ID Smart Card') {
        _pageController.jumpToPage(3);
        return;
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submit();
    }
  }

  void _previousPage() {
    if (_currentStep > 0) {
      if (_currentStep == 3 && _selectedIdType != 'South African ID Smart Card') {
        _pageController.jumpToPage(1);
        return;
      }
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  int get _totalSteps => 4;

  Future<void> _submit() async {
    if (_selfieFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a selfie for verification')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(userRepositoryProvider);
      
      // 1. Upload images with unique names
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      final frontUrl = await repo.uploadVerificationDoc(
        bytes: await _idFrontFile!.readAsBytes(),
        fileName: 'id_front_$timestamp.jpg',
      );

      String? backUrl;
      if (_idBackFile != null) {
        backUrl = await repo.uploadVerificationDoc(
          bytes: await _idBackFile!.readAsBytes(),
          fileName: 'id_back_$timestamp.jpg',
        );
      }

      final selfieUrl = await repo.uploadVerificationDoc(
        bytes: await _selfieFile!.readAsBytes(),
        fileName: 'selfie_$timestamp.jpg',
      );

      // 2. Submit request
      await repo.submitVerification(
        idType: _selectedIdType!,
        idFrontUrl: frontUrl,
        idBackUrl: backUrl,
        selfieUrl: selfieUrl,
      );

      // 3. Refresh profile
      ref.invalidate(profileProvider);

      if (mounted) {
        context.pop(); // Back to Verification Center
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification submitted! Our team will review it within 24-48 hours.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Identity Verification'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${_currentStep + 1} of $_totalSteps',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    Text(
                      '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / _totalSteps,
                    backgroundColor: AppColors.surface,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              children: [
                _buildIdTypeStep(),
                _buildFrontImageStep(),
                _buildBackImageStep(),
                _buildSelfieStep(),
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
                      onPressed: _isLoading ? null : _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: AppColors.borderColor),
                      ),
                      child: const Text('Back', style: TextStyle(color: AppColors.textPrimary)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextPage,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.black,
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.black))
                      : Text(_currentStep == _totalSteps - 1 ? 'Submit' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildIdTypeStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Select Document Type', 
            'Which identity document will you be using for verification?'
          ),
          ..._idTypes.map((type) => _buildSelectionCard(
            title: type,
            isSelected: _selectedIdType == type,
            onTap: () => setState(() => _selectedIdType = type),
            icon: type == 'Passport' ? Icons.public : Icons.badge_outlined,
          )),
        ],
      ),
    );
  }

  Widget _buildSelectionCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
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
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildFrontImageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Front of Document', 
            'Take a clear photo of the front of your $_selectedIdType. Ensure all details are readable and not blurry.'
          ),
          _buildImageUploadArea(
            file: _idFrontFile,
            onTap: () => _pickImage('front'),
            placeholderIcon: Icons.add_a_photo_outlined,
            placeholderText: 'Tap to capture or upload front',
          ),
          const SizedBox(height: 24),
          _buildGuidelineItem(Icons.lightbulb_outline, 'Ensure good lighting and no glare'),
          _buildGuidelineItem(Icons.crop_free, 'All four corners should be visible'),
        ],
      ),
    );
  }

  Widget _buildBackImageStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Back of Document', 
            'Now, take a photo of the back side of your Smart Card.'
          ),
          _buildImageUploadArea(
            file: _idBackFile,
            onTap: () => _pickImage('back'),
            placeholderIcon: Icons.add_a_photo_outlined,
            placeholderText: 'Tap to capture or upload back',
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepHeader(
            'Liveness Check', 
            'Finally, take a selfie to verify it\'s you. Keep your face centered in the frame.'
          ),
          _buildImageUploadArea(
            file: _selfieFile,
            onTap: () => _pickImage('selfie'),
            placeholderIcon: Icons.face_outlined,
            placeholderText: 'Tap to take a selfie',
            isCircular: true,
          ),
          const SizedBox(height: 24),
          _buildGuidelineItem(Icons.face, 'Look straight at the camera'),
          _buildGuidelineItem(Icons.no_photography_outlined, 'Remove glasses, hats, or masks'),
        ],
      ),
    );
  }

  Widget _buildImageUploadArea({
    required File? file,
    required VoidCallback onTap,
    required IconData placeholderIcon,
    required String placeholderText,
    bool isCircular = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isCircular ? 125 : 20),
          border: Border.all(color: AppColors.borderColor, style: BorderStyle.solid),
        ),
        child: file != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(isCircular ? 125 : 20),
              child: Image.file(file, fit: BoxFit.cover),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(placeholderIcon, size: 48, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(placeholderText, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              ],
            ),
      ),
    );
  }

  Widget _buildGuidelineItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 12),
          Text(text, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
