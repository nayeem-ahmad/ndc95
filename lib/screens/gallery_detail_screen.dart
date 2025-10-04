import 'package:flutter/material.dart';
import '../models/gallery.dart';
import '../models/gallery_media.dart';
import '../services/gallery_service.dart';
import '../widgets/media_upload_dialog.dart';
import 'media_viewer_screen.dart';

class GalleryDetailScreen extends StatelessWidget {
  final Gallery gallery;

  const GalleryDetailScreen({super.key, required this.gallery});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar with cover image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.deepPurple.shade700,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                gallery.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (gallery.coverImageUrl != null)
                    Image.network(
                      gallery.coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.deepPurple.shade300,
                          child: const Icon(
                            Icons.photo_library,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.deepPurple.shade300,
                      child: const Icon(
                        Icons.photo_library,
                        size: 80,
                        color: Colors.white,
                      ),
                    ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Gallery info
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (gallery.description.isNotEmpty) ...[
                    Text(
                      gallery.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Icon(Icons.event, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(gallery.occasionDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.people, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        '${gallery.contributorsCount} contributors',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.photo, size: 18, color: Colors.deepPurple.shade700),
                      const SizedBox(width: 8),
                      Text(
                        '${gallery.mediaCount} Photos & Videos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Media grid
          StreamBuilder<List<GalleryMedia>>(
            stream: GalleryService.streamGalleryMedia(gallery.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading media',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final mediaList = snapshot.data!;

              if (mediaList.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.add_photo_alternate, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'No photos yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to add memories!',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.all(8),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final media = mediaList[index];
                      return _buildMediaThumbnail(context, media, mediaList, index);
                    },
                    childCount: mediaList.length,
                  ),
                ),
              );
            },
          ),

          // Bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUploadDialog(context),
        backgroundColor: Colors.deepPurple.shade700,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Add Photos'),
      ),
    );
  }

  Widget _buildMediaThumbnail(
    BuildContext context,
    GalleryMedia media,
    List<GalleryMedia> allMedia,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MediaViewerScreen(
              mediaList: allMedia,
              initialIndex: index,
            ),
          ),
        );
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          if (media.type == MediaType.image)
            Image.network(
              media.url,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                );
              },
            )
          else
            Stack(
              fit: StackFit.expand,
              children: [
                if (media.thumbnailUrl != null)
                  Image.network(
                    media.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.videocam, color: Colors.grey, size: 40),
                      );
                    },
                  )
                else
                  Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.videocam, color: Colors.grey, size: 40),
                  ),
                // Play icon overlay
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.play_arrow, color: Colors.white, size: 32),
                  ),
                ),
              ],
            ),

          // Like indicator
          if (media.likes > 0)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, size: 12, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      '${media.likes}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showUploadDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => MediaUploadDialog(gallery: gallery),
    );
  }
}
