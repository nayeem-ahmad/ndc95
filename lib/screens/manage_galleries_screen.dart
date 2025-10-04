import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../services/gallery_service.dart';
import '../widgets/gallery_editor_dialog.dart';

class ManageGalleriesScreen extends StatefulWidget {
  const ManageGalleriesScreen({super.key});

  @override
  State<ManageGalleriesScreen> createState() => _ManageGalleriesScreenState();
}

class _ManageGalleriesScreenState extends State<ManageGalleriesScreen> {
  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Memories'),
        backgroundColor: Colors.deepPurple.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: StreamBuilder<List<Gallery>>(
          stream: GalleryService.streamAllGalleries(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final galleries = snapshot.data!;

            if (galleries.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.photo_library, size: 80, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No galleries yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first memory gallery!',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: galleries.length,
              itemBuilder: (context, index) {
                final gallery = galleries[index];
                return _buildGalleryCard(gallery);
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showGalleryEditor(null),
        backgroundColor: Colors.deepPurple.shade700,
        icon: const Icon(Icons.add),
        label: const Text('New Gallery'),
      ),
    );
  }

  Widget _buildGalleryCard(Gallery gallery) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          if (gallery.coverImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                gallery.coverImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, size: 64, color: Colors.grey),
                  );
                },
              ),
            )
          else
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.deepPurple.shade100,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 64,
                  color: Colors.deepPurple.shade300,
                ),
              ),
            ),

          // Gallery info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        gallery.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Published badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: gallery.isPublished ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        gallery.isPublished ? 'Published' : 'Draft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      _formatDate(gallery.occasionDate),
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.photo, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${gallery.mediaCount} media',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      '${gallery.contributorsCount} contributors',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
                if (gallery.description.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    gallery.description,
                    style: TextStyle(color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Action buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Toggle publish switch
                Text(
                  gallery.isPublished ? 'Published' : 'Draft',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                  ),
                ),
                Switch(
                  value: gallery.isPublished,
                  onChanged: (value) => _togglePublish(gallery, value),
                  activeColor: Colors.green,
                ),
                const SizedBox(width: 8),
                // Edit button
                TextButton.icon(
                  onPressed: () => _showGalleryEditor(gallery),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.deepPurple.shade700,
                  ),
                ),
                // Delete button
                TextButton.icon(
                  onPressed: () => _confirmDelete(gallery),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGalleryEditor(Gallery? gallery) {
    showDialog(
      context: context,
      builder: (context) => GalleryEditorDialog(gallery: gallery),
    );
  }

  Future<void> _togglePublish(Gallery gallery, bool isPublished) async {
    final success = await GalleryService.setPublished(gallery.id, isPublished);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update gallery status'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(Gallery gallery) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gallery'),
        content: Text(
          'Are you sure you want to delete "${gallery.title}"?\n\n'
          'This will also delete all ${gallery.mediaCount} media items in this gallery.\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final success = await GalleryService.deleteGallery(gallery.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Gallery deleted successfully'
                  : 'Failed to delete gallery',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}
