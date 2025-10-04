import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/gallery.dart';
import '../models/gallery_media.dart';
import 'firebase_service.dart';

class GalleryService {
  static final FirebaseFirestore _firestore = FirebaseService.firestore;
  static const String _galleriesCollection = 'galleries';

  // Stream all published galleries (for members), sorted by occasion date descending
  static Stream<List<Gallery>> streamPublishedGalleries() {
    return _firestore
        .collection(_galleriesCollection)
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final galleries = snapshot.docs.map((doc) => Gallery.fromFirestore(doc)).toList();
      // Sort by occasion date descending (latest first)
      galleries.sort((a, b) => b.occasionDate.compareTo(a.occasionDate));
      return galleries;
    });
  }

  // Stream all galleries (for admins)
  static Stream<List<Gallery>> streamAllGalleries() {
    return _firestore
        .collection(_galleriesCollection)
        .snapshots()
        .map((snapshot) {
      final galleries = snapshot.docs.map((doc) => Gallery.fromFirestore(doc)).toList();
      // Sort by occasion date descending (latest first)
      galleries.sort((a, b) => b.occasionDate.compareTo(a.occasionDate));
      return galleries;
    });
  }

  // Get a single gallery by ID
  static Future<Gallery?> getGallery(String galleryId) async {
    try {
      final doc = await _firestore.collection(_galleriesCollection).doc(galleryId).get();
      if (doc.exists) {
        return Gallery.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting gallery: $e');
      return null;
    }
  }

  // Create a new gallery
  static Future<String?> createGallery(Gallery gallery) async {
    try {
      final docRef = await _firestore.collection(_galleriesCollection).add(gallery.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating gallery: $e');
      return null;
    }
  }

  // Update a gallery
  static Future<bool> updateGallery(String galleryId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_galleriesCollection).doc(galleryId).update(updates);
      return true;
    } catch (e) {
      print('Error updating gallery: $e');
      return false;
    }
  }

  // Delete a gallery and all its media
  static Future<bool> deleteGallery(String galleryId) async {
    try {
      // Delete all media in the gallery
      final mediaSnapshot = await _firestore
          .collection(_galleriesCollection)
          .doc(galleryId)
          .collection('media')
          .get();

      for (var doc in mediaSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete the gallery
      await _firestore.collection(_galleriesCollection).doc(galleryId).delete();
      return true;
    } catch (e) {
      print('Error deleting gallery: $e');
      return false;
    }
  }

  // Toggle publish status
  static Future<bool> setPublished(String galleryId, bool isPublished) async {
    return updateGallery(galleryId, {'isPublished': isPublished});
  }

  // Upload cover image
  static Future<String?> uploadCoverImage(String galleryId, String fileName, List<int> fileBytes) async {
    try {
      final url = await FirebaseService.uploadGalleryCover(galleryId, fileName, fileBytes);
      if (url != null) {
        await updateGallery(galleryId, {'coverImageUrl': url});
      }
      return url;
    } catch (e) {
      print('Error uploading cover image: $e');
      return null;
    }
  }

  // MEDIA OPERATIONS

  // Stream media for a gallery
  static Stream<List<GalleryMedia>> streamGalleryMedia(String galleryId) {
    return _firestore
        .collection(_galleriesCollection)
        .doc(galleryId)
        .collection('media')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => GalleryMedia.fromFirestore(doc)).toList());
  }

  // Add media to a gallery
  static Future<String?> addMedia(GalleryMedia media) async {
    try {
      final docRef = await _firestore
          .collection(_galleriesCollection)
          .doc(media.galleryId)
          .collection('media')
          .add(media.toFirestore());

      // Update gallery media count and contributors
      await _updateGalleryStats(media.galleryId, media.uploadedByUid);

      return docRef.id;
    } catch (e) {
      print('Error adding media: $e');
      return null;
    }
  }

  // Update media count and contributors count for a gallery
  static Future<void> _updateGalleryStats(String galleryId, String contributorUid) async {
    try {
      final galleryRef = _firestore.collection(_galleriesCollection).doc(galleryId);
      final galleryDoc = await galleryRef.get();
      
      if (galleryDoc.exists) {
        final data = galleryDoc.data() as Map<String, dynamic>;
        final mediaCount = (data['mediaCount'] ?? 0) + 1;
        
        // Get unique contributors
        final mediaSnapshot = await galleryRef.collection('media').get();
        final contributors = <String>{};
        for (var doc in mediaSnapshot.docs) {
          final mediaData = doc.data();
          contributors.add(mediaData['uploadedByUid'] as String);
        }
        
        await galleryRef.update({
          'mediaCount': mediaCount,
          'contributorsCount': contributors.length,
        });
      }
    } catch (e) {
      print('Error updating gallery stats: $e');
    }
  }

  // Delete media
  static Future<bool> deleteMedia(String galleryId, String mediaId) async {
    try {
      await _firestore
          .collection(_galleriesCollection)
          .doc(galleryId)
          .collection('media')
          .doc(mediaId)
          .delete();

      // Update gallery stats
      final galleryRef = _firestore.collection(_galleriesCollection).doc(galleryId);
      final galleryDoc = await galleryRef.get();
      
      if (galleryDoc.exists) {
        final data = galleryDoc.data() as Map<String, dynamic>;
        final mediaCount = (data['mediaCount'] ?? 1) - 1;
        await galleryRef.update({'mediaCount': mediaCount > 0 ? mediaCount : 0});
      }

      return true;
    } catch (e) {
      print('Error deleting media: $e');
      return false;
    }
  }

  // Toggle like on media
  static Future<bool> toggleLike(String galleryId, String mediaId, String userId) async {
    try {
      final mediaRef = _firestore
          .collection(_galleriesCollection)
          .doc(galleryId)
          .collection('media')
          .doc(mediaId);

      final doc = await mediaRef.get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      final likedBy = List<String>.from(data['likedBy'] ?? []);
      final isLiked = likedBy.contains(userId);

      if (isLiked) {
        likedBy.remove(userId);
      } else {
        likedBy.add(userId);
      }

      await mediaRef.update({
        'likedBy': likedBy,
        'likes': likedBy.length,
      });

      return true;
    } catch (e) {
      print('Error toggling like: $e');
      return false;
    }
  }

  // Upload media file
  static Future<String?> uploadMediaFile(
    String galleryId,
    String fileName,
    List<int> fileBytes,
    MediaType type,
  ) async {
    try {
      return await FirebaseService.uploadGalleryMedia(galleryId, fileName, fileBytes, type);
    } catch (e) {
      print('Error uploading media file: $e');
      return null;
    }
  }
}
