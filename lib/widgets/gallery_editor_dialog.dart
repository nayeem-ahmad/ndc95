import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart';
import '../services/firebase_service.dart';
import '../utils/file_bytes_loader.dart';

class GalleryEditorDialog extends StatefulWidget {
  final Gallery? gallery; // null for new gallery, non-null for editing

  const GalleryEditorDialog({super.key, this.gallery});

  @override
  State<GalleryEditorDialog> createState() => _GalleryEditorDialogState();
}

class _GalleryEditorDialogState extends State<GalleryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;
  
  DateTime? _selectedDate;
  String? _coverImageUrl;
  bool _isPublished = false;

  bool get _isEditMode => widget.gallery != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.gallery?.title ?? '');
    _descriptionController = TextEditingController(text: widget.gallery?.description ?? '');
    _tagsController = TextEditingController(text: widget.gallery?.tags.join(', ') ?? '');
    
    _selectedDate = widget.gallery?.occasionDate;
    _coverImageUrl = widget.gallery?.coverImageUrl;
    _isPublished = widget.gallery?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        List<int>? fileBytes = file.bytes;
        
        if (fileBytes == null) {
          fileBytes = await loadFileBytes(file);
          if (fileBytes == null) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to read file'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        }

        // If editing, upload immediately
        if (_isEditMode && widget.gallery != null) {
          setState(() => _isSaving = true);
          
          final url = await GalleryService.uploadCoverImage(
            widget.gallery!.id,
            file.name,
            fileBytes,
          );

          setState(() => _isSaving = false);

          if (url != null) {
            setState(() {
              _coverImageUrl = url;
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cover image updated!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Failed to upload cover image'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // For new gallery, just store temporarily
          // TODO: Store file bytes for later upload after gallery creation
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cover image selected. Save gallery to upload.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error picking cover image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGallery() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select occasion date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      final userDoc = await FirebaseService.getUserProfile(currentUser.uid);
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] ?? currentUser.email ?? 'Unknown';

      final tags = _tagsController.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      if (_isEditMode) {
        // Update existing gallery
        final updates = {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'occasionDate': _selectedDate,
          'tags': tags,
          'isPublished': _isPublished,
        };

        final success = await GalleryService.updateGallery(widget.gallery!.id, updates);

        if (success && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new gallery
        final newGallery = Gallery(
          id: '', // Will be set by Firestore
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          occasionDate: _selectedDate!,
          coverImageUrl: _coverImageUrl,
          createdByUid: currentUser.uid,
          createdByName: userName,
          createdAt: DateTime.now(),
          isPublished: _isPublished,
          tags: tags,
        );

        final galleryId = await GalleryService.createGallery(newGallery);

        if (galleryId != null && mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gallery created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade700,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    _isEditMode ? Icons.edit : Icons.add_photo_alternate,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isEditMode ? 'Edit Gallery' : 'Create New Gallery',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Gallery Title *',
                          hintText: 'e.g., Annual Reunion 2024',
                          prefixIcon: Icon(Icons.title),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe this memory...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Occasion Date
                      InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Occasion Date *',
                            prefixIcon: Icon(Icons.event),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _selectedDate != null
                                ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                                : 'Tap to select date',
                            style: TextStyle(
                              color: _selectedDate != null ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tags
                      TextFormField(
                        controller: _tagsController,
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma-separated)',
                          hintText: 'reunion, 2024, dhaka',
                          prefixIcon: Icon(Icons.label),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Cover Image
                      const Text(
                        'Cover Image',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_coverImageUrl != null)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _coverImageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                onPressed: () {
                                  setState(() => _coverImageUrl = null);
                                },
                                icon: const Icon(Icons.close),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _pickCoverImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Add Cover Image'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Published checkbox
                      CheckboxListTile(
                        value: _isPublished,
                        onChanged: (value) {
                          setState(() {
                            _isPublished = value ?? false;
                          });
                        },
                        title: const Text('Publish Gallery'),
                        subtitle: const Text('Members can view and contribute'),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveGallery,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Icon(_isEditMode ? Icons.save : Icons.add),
                    label: Text(_isSaving ? 'Saving...' : (_isEditMode ? 'Update' : 'Create')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple.shade700,
                      foregroundColor: Colors.white,
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
}
