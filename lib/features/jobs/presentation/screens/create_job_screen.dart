import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/job.dart';
import '../../../../core/services/supabase_service.dart';
import '../providers/jobs_provider.dart';

class CreateJobScreen extends ConsumerStatefulWidget {
  final Job? job;

  const CreateJobScreen({
    Key? key,
    this.job,
  }) : super(key: key);

  @override
  ConsumerState<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends ConsumerState<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _budgetController;
  late DateTime _selectedDeadline;
  late String _selectedCategory;
  final List<dynamic> _images = [];

  final List<String> _categories = [
    'Design',
    'Development',
    'Marketing',
    'Writing',
    'Video',
    'Music',
    'Photography',
    'Tutoring',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    final job = widget.job;
    _titleController = TextEditingController(text: job?.title ?? '');
    _descriptionController = TextEditingController(text: job?.description ?? '');
    _budgetController = TextEditingController(text: job?.budget.toString() ?? '');
    _selectedDeadline = job?.deadline ?? DateTime.now().add(const Duration(days: 7));
    _selectedCategory = job?.category ?? 'Design';
    if (job != null) {
      _images.addAll(job.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.darkBg,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
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
        // Handle images
        for (final item in _images) {
          if (item is String) {
            imageUrls.add(item);
          } else if (item is File) {
            final bytes = await item.readAsBytes();
            final url = await jobNotifier.uploadImage(bytes);
            if (url != null) {
              imageUrls.add(url);
            }
          }
        }

        final data = {
          'client_id': currentUser.id,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
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
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Job' : 'Post a Job'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g., Need a website for my bakery',
                  labelText: 'Job Title',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Describe the job requirements in detail...',
                  labelText: 'Description',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Category & Budget
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                      ),
                      dropdownColor: AppColors.surface,
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat, style: const TextStyle(color: AppColors.textPrimary)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedCategory = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _budgetController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        labelText: 'Budget (R)',
                        prefixText: 'R ',
                        prefixStyle: TextStyle(color: AppColors.primary),
                      ),
                      validator: (value) =>
                          value == null || double.tryParse(value) == null
                              ? 'Invalid amount'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline
              GestureDetector(
                onTap: _selectDeadline,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderColor),
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
                              color: AppColors.textPrimary,
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
                  color: AppColors.textPrimary,
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
                          borderRadius: BorderRadius.circular(8),
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
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.borderColor),
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
                height: 48,
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
      ),
    );
  }
}
