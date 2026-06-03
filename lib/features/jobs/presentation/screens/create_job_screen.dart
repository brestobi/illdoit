import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/job.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/repositories/location_repository.dart';
import '../../../../core/repositories/category_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../providers/jobs_provider.dart';

class CreateJobScreen extends ConsumerStatefulWidget {

  const CreateJobScreen({super.key, 
    this.job,
  });
  final Job? job;

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late TextEditingController _categorySearchController;
  late DateTime _selectedDeadline;
  String? _selectedCategory;
  String? _selectedLocation;
  late String _jobType;
  final List<dynamic> _images = [];

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _titleController = TextEditingController(text: job?.title ?? '');
    _descriptionController = TextEditingController(text: job?.description ?? '');
    _budgetController = TextEditingController(text: job?.budget.toString() ?? '');
    _categorySearchController = TextEditingController(text: job?.category ?? '');
    _selectedDeadline = job?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _selectedCategory = job?.category;
    _jobType = job?.jobType ?? 'digital';
    _selectedLocation = job?.location;
    if (job != null) {
      _images.addAll(job.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _categorySearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.darkBg,
              surface: Theme.of(context).brightness == Brightness.dark ? AppColors.surface : Colors.white,
              onSurface: Theme.of(context).brightness == Brightness.dark ? AppColors.textPrimary : Colors.black,
            ),
          ),
          child: child!,
        ),
    );

    if (picked != null) {
      setState(() => _selectedDeadline = picked);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(supabaseServiceProvider).currentUser;
      if (currentUser == null) return;

      final List<String> imageUrls = [];
      final jobNotifier = ref.read(jobNotifierProvider.notifier);

      try {
        // Handle images in parallel
        final uploadTasks = _images.map((item) async {
          if (item is String) {
            return item;
          } else if (item is File) {
            final bytes = await item.readAsBytes();
            return jobNotifier.uploadImage(bytes);
          }
          return null;
        }).toList();

        final results = await Future.wait(uploadTasks);
        imageUrls.addAll(results.whereType<String>());

        final data = {
          'client_id': currentUser.id,
          'job_type': _jobType,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'location': _selectedLocation,
          'budget': double.parse(_budgetController.text),
          'deadline': _selectedDeadline.toIso8601String(),
          'images': imageUrls,
          'status': widget.job?.status ?? 'open',
        };

        if (widget.job != null) {
          await jobNotifier.updateJob(widget.job!.id, data);
        } else {
          await jobNotifier.createJob(data);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving job: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobNotifierProvider);
    final profileAsync = ref.watch(profileProvider);
    final locationsAsync = ref.watch(locationsProvider);
    final digitalCategoriesAsync = ref.watch(digitalCategoriesProvider);
    final physicalCategoriesAsync = ref.watch(physicalCategoriesProvider);
    final isEditing = widget.job != null;

    ref.listen<JobState>(jobNotifierProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Job updated successfully!' : 'Job posted successfully!')),
        );
        context.pop();
        ref.read(jobNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job' : 'Post a Job'),
        elevation: 0,
      ),
      body: profileAsync.when(
        data: (user) {
          if (user == null) return const Center(child: Text('User not found'));
          
          if (!user.isVerified) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 80, color: AppColors.textSecondary),
                    const SizedBox(height: 24),
                    const Text(
                      'Verification Required',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'To maintain a safe community, you must verify your identity before posting jobs.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => context.push(AppRoutes.verificationCenter),
                        child: const Text('Get Verified Now'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Job Details',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Job Type
                  const Text(
                    'Job Type',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildTypeChoice('digital', Icons.computer, 'Digital'),
                      const SizedBox(width: 12),
                      _buildTypeChoice('physical', Icons.hail, 'Physical'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g., Need a website for my bakery',
                      labelText: 'Job Title',
                    ),
                    validator: Validators.title,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Describe the job requirements in detail...',
                      labelText: 'Description',
                    ),
                    validator: Validators.description,
                  ),
                  const SizedBox(height: 16),

                  // Category Selector
                  if (_jobType == 'digital')
                    digitalCategoriesAsync.when(
                      data: (categories) => DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Digital Category',
                          prefixIcon: Icon(Icons.category_outlined, size: 20),
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: categories.map((cat) => DropdownMenuItem(
                            value: cat.name,
                            child: Text(cat.name),
                          )).toList(),
                        onChanged: (value) {
                          setState(() => _selectedCategory = value);
                        },
                        validator: (value) => value == null ? 'Please select a category' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    )
                  else
                    physicalCategoriesAsync.when(
                      data: (categories) => Autocomplete<String>(
                        initialValue: TextEditingValue(text: _selectedCategory ?? ''),
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return categories.map((e) => e.name);
                          }
                          return categories
                              .where((cat) => cat.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
                              .map((e) => e.name);
                        },
                        onSelected: (String selection) {
                          setState(() => _selectedCategory = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) => TextFormField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Physical Category (Search as you type)',
                              hintText: 'e.g. Plumbing, Electrician...',
                              prefixIcon: Icon(Icons.search_rounded, size: 20),
                            ),
                            validator: (value) => (value == null || value.isEmpty) ? 'Please select a category' : null,
                          ),
                        optionsViewBuilder: (context, onSelected, options) => Align(
                            alignment: Alignment.topLeft,
                            child: Material(
                              elevation: 4,
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surface,
                              child: Container(
                                width: MediaQuery.of(context).size.width - 32,
                                constraints: const BoxConstraints(maxHeight: 200),
                                child: ListView.builder(
                                  padding: EdgeInsets.zero,
                                  shrinkWrap: true,
                                  itemCount: options.length,
                                  itemBuilder: (BuildContext context, int index) {
                                    final String option = options.elementAt(index);
                                    return ListTile(
                                      title: Text(option),
                                      onTap: () => onSelected(option),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error: $err'),
                    ),
                  const SizedBox(height: 16),

                  // Budget
                  TextFormField(
                    controller: _budgetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: '0.00',
                      labelText: 'Budget (R)',
                      prefixText: 'R ',
                      prefixStyle: TextStyle(color: AppColors.primary),
                    ),
                    validator: Validators.budget,
                  ),
                  const SizedBox(height: 16),

                  // Location
                  if (_jobType == 'physical') ...[
                    locationsAsync.when(
                      data: (locations) => DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: const InputDecoration(
                          labelText: 'Job Location (City)',
                          prefixIcon: Icon(Icons.location_on_outlined, size: 20),
                        ),
                        dropdownColor: Theme.of(context).colorScheme.surface,
                        items: locations.map((loc) => DropdownMenuItem(
                            value: loc.name,
                            child: Text(loc.name),
                          )).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedLocation = value);
                          }
                        },
                        validator: (value) => _jobType == 'physical' && value == null ? 'Location is required for physical jobs' : null,
                      ),
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text('Error loading cities: $err'),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Deadline
                  GestureDetector(
                    onTap: _selectDeadline,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Deadline',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                              Text(
                                DateFormat('MMM dd, yyyy').format(_selectedDeadline),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Images
                  const Text(
                    'Job Images (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        ..._images.map((item) {
                          final DecorationImage image;
                          if (item is String) {
                            image = DecorationImage(image: NetworkImage(item), fit: BoxFit.cover);
                          } else {
                            image = DecorationImage(image: FileImage(item), fit: BoxFit.cover);
                          }

                          return Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: image,
                            ),
                            child: Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _images.remove(item);
                                  });
                                },
                              ),
                            ),
                          );
                        }),
                        if (_images.length < 3)
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                              ),
                              child: const Icon(
                                Icons.add_a_photo_outlined,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Post Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _handleSave,
                      child: state.isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(isEditing ? 'Save Changes' : 'Post Job'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTypeChoice(String type, IconData icon, String label) {
    final isSelected = _jobType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
           setState(() {
            _jobType = type;
            _selectedCategory = null; // Reset category when switching type
            if (type == 'digital') _selectedLocation = null;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : Theme.of(context).colorScheme.outline.withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
