import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/service.dart';
import '../../../../core/services/supabase_service.dart';
import '../providers/services_provider.dart';

class CreateServiceScreen extends ConsumerStatefulWidget {
  final Service? service;

  const CreateServiceScreen({
    Key? key,
    this.service,
  }) : super(key: key);

  @override
  ConsumerState<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends ConsumerState<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _deliveryTimeController;
  late String _selectedCategory;
  final List<dynamic> _images = []; // Can be File or String (URL)

  final List<String> _categories = [
    'Graphic Design',
    'Web Development',
    'Tutoring',
    'Video Editing',
    'CV Writing',
    'Photography',
    'Social Media Help',
    'AI Services',
    'Music & Audio',
    'Tech Support',
  ];

  @override
  void initState() {
    super.initState();
    final service = widget.service;
    _titleController = TextEditingController(text: service?.title ?? '');
    _descriptionController = TextEditingController(text: service?.description ?? '');
    _priceController = TextEditingController(text: service?.price.toString() ?? '');
    _deliveryTimeController = TextEditingController(text: service?.deliveryTime.toString() ?? '');
    _selectedCategory = service?.category ?? 'Graphic Design';
    if (service != null) {
      _images.addAll(service.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _deliveryTimeController.dispose();
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
        _images.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      final currentUser = ref.read(supabaseServiceProvider).currentUser;
      if (currentUser == null) return;

      final List<String> imageUrls = [];
      final serviceNotifier = ref.read(serviceNotifierProvider.notifier);

      try {
        // Handle images
        for (final item in _images) {
          if (item is String) {
            imageUrls.add(item);
          } else if (item is File) {
            final bytes = await item.readAsBytes();
            final url = await serviceNotifier.uploadImage(bytes);
            if (url != null) {
              imageUrls.add(url);
            }
          }
        }

        final data = {
          'user_id': currentUser.id,
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          'price': double.parse(_priceController.text),
          'delivery_time': int.parse(_deliveryTimeController.text),
          'images': imageUrls,
          'is_active': true,
        };

        if (widget.service != null) {
          await serviceNotifier.updateService(widget.service!.id, data);
        } else {
          await serviceNotifier.createService(data);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving service: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(serviceNotifierProvider);
    final isEditing = widget.service != null;

    ref.listen<ServiceState>(serviceNotifierProvider, (previous, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
      } else if (next.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEditing ? 'Service updated successfully!' : 'Service created successfully!')),
        );
        context.pop();
        ref.read(serviceNotifierProvider.notifier).reset();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Service' : 'Create Service'),
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
                'Service Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker
              const Text(
                'Service Images',
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
                    if (_images.length < 5)
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
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g., I will design a professional logo',
                  labelText: 'Service Title',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Describe what you offer in detail...',
                  labelText: 'Description',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<String>(
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
              const SizedBox(height: 16),

              // Price & Delivery Time
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        labelText: 'Price (R)',
                        prefixText: 'R ',
                        prefixStyle: TextStyle(color: AppColors.primary),
                      ),
                      validator: (value) =>
                          value == null || double.tryParse(value) == null
                              ? 'Invalid price'
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryTimeController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: const InputDecoration(
                        hintText: '3',
                        labelText: 'Delivery (Days)',
                      ),
                      validator: (value) =>
                          value == null || int.tryParse(value) == null
                              ? 'Invalid days'
                              : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
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
                      : Text(isEditing ? 'Save Changes' : 'Publish Service'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
