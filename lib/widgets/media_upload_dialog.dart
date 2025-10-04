import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/gallery.dart';
import '../models/gallery_media.dart';
import '../services/gallery_service.dart';
import '../services/firebase_service.dart';
import '../utils/file_bytes_loader.dart';

class MediaUploadDialog extends StatefulWidget {
  final Gallery gallery;

  const MediaUploadDialog({super.key, required this.gallery});

  @override
  State<MediaUploadDialog> createState() => _MediaUploadDialogState();
}

class _MediaUploadDialogState extends State<MediaUploadDialog> {
  final _captionController = TextEditingController();
  final List<PlatformFile> _selectedFiles = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'mov'],
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFiles.addAll(result.files);
        });
      }
    } catch (e) {
      print('Error picking files: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadMedia() async {
    if (_selectedFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseService.currentUser;
      if (currentUser == null) {
        throw 'User not authenticated';
      }

      final userDoc = await FirebaseService.getUserProfile(currentUser.uid);
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['displayName'] ?? currentUser.email ?? 'Unknown';

      int uploaded = 0;

      for (final file in _selectedFiles) {
        List<int>? fileBytes = file.bytes;
        
        if (fileBytes == null) {
          fileBytes = await loadFileBytes(file);
          if (fileBytes == null) {
            print('Failed to read file: ${file.name}');
            continue;
          }
        }

        // Determine media type
        final extension = file.extension?.toLowerCase() ?? '';
        final isVideo = ['mp4', 'mov', 'avi'].contains(extension);
        final mediaType = isVideo ? MediaType.video : MediaType.image;

        // Upload file
        final url = await GalleryService.uploadMediaFile(
          widget.gallery.id,
          file.name,
          fileBytes,
          mediaType,
        );

        if (url != null) {
          // Create media document
          final media = GalleryMedia(
            id: '', // Will be set by Firestore
            galleryId: widget.gallery.id,
            type: mediaType,
            url: url,
            caption: _captionController.text.trim(),
            uploadedByUid: currentUser.uid,
            uploadedByName: userName,
            uploadedAt: DateTime.now(),
          );

          await GalleryService.addMedia(media);
          uploaded++;
        }

        // Update progress
        setState(() {
          _uploadProgress = uploaded / _selectedFiles.length;
        });
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully uploaded $uploaded of ${_selectedFiles.length} files!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error uploading media: $e');
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
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                  const Icon(Icons.add_a_photo, color: Colors.white),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Photos/Videos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Caption field
                    TextField(
                      controller: _captionController,
                      decoration: const InputDecoration(
                        labelText: 'Caption (optional)',
                        hintText: 'Add a caption for your photos...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.text_fields),
                      ),
                      maxLines: 3,
                      enabled: !_isUploading,
                    ),
                    const SizedBox(height: 20),

                    // Select files button
                    OutlinedButton.icon(
                      onPressed: _isUploading ? null : _pickFiles,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(_selectedFiles.isEmpty
                          ? 'Select Photos/Videos'
                          : 'Add More Files'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Selected files list
                    if (_selectedFiles.isNotEmpty) ...[
                      const Text(
                        'Selected Files:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...List.generate(_selectedFiles.length, (index) {
                        final file = _selectedFiles[index];
                        return ListTile(
                          leading: Icon(
                            _isVideo(file) ? Icons.videocam : Icons.image,
                            color: Colors.deepPurple,
                          ),
                          title: Text(
                            file.name,
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _formatFileSize(file.size),
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          trailing: _isUploading
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    setState(() {
                                      _selectedFiles.removeAt(index);
                                    });
                                  },
                                ),
                        );
                      }),
                    ],

                    // Upload progress
                    if (_isUploading) ...[
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: _uploadProgress,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading... ${(_uploadProgress * 100).toInt()}%',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
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
                    onPressed: _isUploading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isUploading ? null : _uploadMedia,
                    icon: _isUploading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.upload),
                    label: Text(_isUploading ? 'Uploading...' : 'Upload'),
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

  bool _isVideo(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    return ['mp4', 'mov', 'avi'].contains(extension);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
