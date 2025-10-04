import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/notice.dart';
import '../services/notice_service.dart';
import '../utils/file_bytes_loader.dart';

Future<Notice?> showNoticeEditorDialog({
  required BuildContext context,
  required Notice initialNotice,
}) {
  return showDialog<Notice>(
    context: context,
    barrierDismissible: false,
    builder: (context) => NoticeEditorDialog(initialNotice: initialNotice),
  );
}

class NoticeEditorDialog extends StatefulWidget {
  final Notice initialNotice;

  const NoticeEditorDialog({super.key, required this.initialNotice});

  @override
  State<NoticeEditorDialog> createState() => _NoticeEditorDialogState();
}

class _NoticeEditorDialogState extends State<NoticeEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _summaryController;
  late TextEditingController _detailsController;
  late TextEditingController _eventTimeController;
  late TextEditingController _locationController;
  late TextEditingController _rsvpLinkController;
  late TextEditingController _contactPhoneController;
  late TextEditingController _contactEmailController;
  late TextEditingController _bannerImageController;

  late String _category;
  late DateTime _visibleUntil;
  DateTime? _eventDate;
  late bool _isPublished;
  late bool _isPinned;

  bool _isSaving = false;
  bool _isUploadingBanner = false;
  String? _bannerUploadError;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialNotice.title);
    _summaryController = TextEditingController(
      text: widget.initialNotice.summary,
    );
    _detailsController = TextEditingController(
      text: widget.initialNotice.details ?? '',
    );
    _eventTimeController = TextEditingController(
      text: widget.initialNotice.eventTime ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialNotice.location ?? '',
    );
    _rsvpLinkController = TextEditingController(
      text: widget.initialNotice.rsvpLink ?? '',
    );
    _contactPhoneController = TextEditingController(
      text: widget.initialNotice.contactPhone ?? '',
    );
    _contactEmailController = TextEditingController(
      text: widget.initialNotice.contactEmail ?? '',
    );
    _bannerImageController = TextEditingController(
      text: widget.initialNotice.bannerImageUrl ?? '',
    );

    _bannerImageController.addListener(_onBannerUrlChanged);

    _category = widget.initialNotice.category;
    _visibleUntil = widget.initialNotice.visibleUntil;
    _eventDate = widget.initialNotice.eventDate;
    _isPublished = widget.initialNotice.isPublished;
    _isPinned = widget.initialNotice.isPinned;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    _detailsController.dispose();
    _eventTimeController.dispose();
    _locationController.dispose();
    _rsvpLinkController.dispose();
    _contactPhoneController.dispose();
    _contactEmailController.dispose();
    _bannerImageController
      ..removeListener(_onBannerUrlChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialNotice.id.isEmpty ? 'Create Notice' : 'Edit Notice',
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(
                  controller: _titleController,
                  label: 'Title',
                  required: true,
                  maxLength: 80,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _summaryController,
                  label: 'Summary',
                  required: true,
                  maxLines: 3,
                  maxLength: 250,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'General', child: Text('General')),
                    DropdownMenuItem(value: 'Event', child: Text('Event')),
                    DropdownMenuItem(
                      value: 'Announcement',
                      child: Text('Announcement'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _category = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Visible until',
                  value: _visibleUntil,
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visibleUntil = value);
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isPublished,
                  onChanged: (value) => setState(() => _isPublished = value),
                  title: const Text('Published'),
                  subtitle: const Text(
                    'Published notices are visible to members.',
                  ),
                ),
                SwitchListTile(
                  value: _isPinned,
                  onChanged: (value) => setState(() => _isPinned = value),
                  title: const Text('Pin notice'),
                  subtitle: const Text(
                    'Pinned notices show at the front of the carousel.',
                  ),
                ),
                const Divider(height: 32),
                Text(
                  'Optional event details',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                _DateField(
                  label: 'Event date (optional)',
                  value: _eventDate,
                  onChanged: (value) => setState(() => _eventDate = value),
                  allowNull: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _eventTimeController,
                  label: 'Event time (optional)',
                  hintText: 'e.g., 7:00 PM',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _locationController,
                  label: 'Location (optional)',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _detailsController,
                  label: 'Details (optional)',
                  maxLines: 5,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _rsvpLinkController,
                  label: 'RSVP link (optional)',
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _contactPhoneController,
                  label: 'Contact phone (optional)',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _contactEmailController,
                  label: 'Contact email (optional)',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _buildBannerImageField(context),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _handleSave,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(widget.initialNotice.id.isEmpty ? 'Create' : 'Save'),
        ),
      ],
    );
  }

  void _onBannerUrlChanged() {
    setState(() {
      _bannerUploadError = null;
    });
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool required = false,
    String? hintText,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        border: const OutlineInputBorder(),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required field';
              }
              return null;
            }
          : null,
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    final updatedNotice = widget.initialNotice.copyWith(
      title: _titleController.text.trim(),
      summary: _summaryController.text.trim(),
      category: _category,
      visibleUntil: _visibleUntil,
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
      eventDate: _eventDate,
      eventTime: _eventTimeController.text.trim().isEmpty
          ? null
          : _eventTimeController.text.trim(),
      location: _locationController.text.trim().isEmpty
          ? null
          : _locationController.text.trim(),
      rsvpLink: _rsvpLinkController.text.trim().isEmpty
          ? null
          : _rsvpLinkController.text.trim(),
      contactPhone: _contactPhoneController.text.trim().isEmpty
          ? null
          : _contactPhoneController.text.trim(),
      contactEmail: _contactEmailController.text.trim().isEmpty
          ? null
          : _contactEmailController.text.trim(),
      bannerImageUrl: _bannerImageController.text.trim().isEmpty
          ? null
          : _bannerImageController.text.trim(),
      isPublished: _isPublished,
      isPinned: _isPinned,
    );

    setState(() => _isSaving = false);
    if (!mounted) return;
    Navigator.of(context).pop(updatedNotice);
  }

  Widget _buildBannerImageField(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _bannerImageController,
                decoration: InputDecoration(
                  labelText: 'Banner image URL (optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: _bannerImageController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear URL',
                          onPressed: _isUploadingBanner
                              ? null
                              : () {
                                  _bannerImageController.clear();
                                },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploadingBanner ? null : _pickAndUploadBanner,
                icon: _isUploadingBanner
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload_outlined),
                label: Text(_isUploadingBanner ? 'Uploading…' : 'Upload'),
              ),
            ),
          ],
        ),
        if (_bannerUploadError != null) ...[
          const SizedBox(height: 8),
          Text(
            _bannerUploadError!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.red.shade600,
            ),
          ),
        ],
        if (_bannerImageController.text.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 3 / 1.2,
              child: Image.network(
                _bannerImageController.text,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Preview unavailable',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickAndUploadBanner() async {
    try {
      debugPrint('🔵 Starting banner image picker...');
      setState(() {
        _isUploadingBanner = true;
        _bannerUploadError = null;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: false,
        withData: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (result == null || result.files.isEmpty) {
        debugPrint('⚠️ User cancelled file picker or no files selected');
        setState(() => _isUploadingBanner = false);
        return;
      }

      final file = result.files.single;
      debugPrint('✅ File picked: ${file.name}, size: ${file.size} bytes');

      final bytes = await loadFileBytes(file);

      if (bytes == null) {
        debugPrint('❌ Failed to load file bytes');
        setState(() {
          _bannerUploadError = 'Unable to read the selected file.';
          _isUploadingBanner = false;
        });
        return;
      }

      debugPrint('✅ File bytes loaded: ${bytes.length} bytes');
      final extension = (file.extension ?? 'jpg').toLowerCase();
      final contentType = _inferContentType(extension);
      debugPrint('🔵 Uploading to Firebase Storage... Content-Type: $contentType');

      final downloadUrl = await NoticeService.uploadBannerImage(
        data: bytes,
        fileName: file.name,
        contentType: contentType,
      );

      if (!mounted) return;

      if (downloadUrl == null) {
        debugPrint('❌ Upload returned null URL');
        setState(() {
          _bannerUploadError = 'Upload failed. Please try again.';
          _isUploadingBanner = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload banner image.'),
            backgroundColor: Colors.red.shade600,
          ),
        );
        return;
      }

      debugPrint('✅ Upload successful! URL: $downloadUrl');
      setState(() {
        _bannerImageController.text = downloadUrl;
        _isUploadingBanner = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner image uploaded successfully.')),
      );
    } catch (error, stackTrace) {
      debugPrint('❌ Banner upload error: $error');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      setState(() {
        _bannerUploadError = 'Upload failed: $error';
        _isUploadingBanner = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: $error'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  String? _inferContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool allowNull;

  const _DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.allowNull = false,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = value != null
        ? '${value!.day.toString().padLeft(2, '0')}/${value!.month.toString().padLeft(2, '0')}/${value!.year}'
        : 'Not set';

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      child: Row(
        children: [
          Expanded(child: Text(displayValue)),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final now = DateTime.now();
              final initialDate = value ?? now;
              final picked = await showDatePicker(
                context: context,
                initialDate: initialDate.isBefore(now) ? now : initialDate,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 5),
              );

              if (picked != null) {
                onChanged(DateTime(picked.year, picked.month, picked.day));
              }
            },
          ),
          if (allowNull && value != null)
            IconButton(
              icon: const Icon(Icons.clear),
              tooltip: 'Clear date',
              onPressed: () => onChanged(null),
            ),
        ],
      ),
    );
  }
}
