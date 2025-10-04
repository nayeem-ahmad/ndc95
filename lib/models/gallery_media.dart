import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType { image, video }

class GalleryMedia {
  final String id;
  final String galleryId;
  final MediaType type;
  final String url;
  final String? thumbnailUrl;
  final String caption;
  final String uploadedByUid;
  final String uploadedByName;
  final DateTime uploadedAt;
  final int likes;
  final List<String> likedBy;

  GalleryMedia({
    required this.id,
    required this.galleryId,
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.caption = '',
    required this.uploadedByUid,
    required this.uploadedByName,
    required this.uploadedAt,
    this.likes = 0,
    this.likedBy = const [],
  });

  factory GalleryMedia.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryMedia(
      id: doc.id,
      galleryId: data['galleryId'] ?? '',
      type: data['type'] == 'video' ? MediaType.video : MediaType.image,
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'],
      caption: data['caption'] ?? '',
      uploadedByUid: data['uploadedByUid'] ?? '',
      uploadedByName: data['uploadedByName'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp).toDate(),
      likes: data['likes'] ?? 0,
      likedBy: List<String>.from(data['likedBy'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'galleryId': galleryId,
      'type': type == MediaType.video ? 'video' : 'image',
      'url': url,
      'thumbnailUrl': thumbnailUrl,
      'caption': caption,
      'uploadedByUid': uploadedByUid,
      'uploadedByName': uploadedByName,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'likes': likes,
      'likedBy': likedBy,
    };
  }

  GalleryMedia copyWith({
    String? id,
    String? galleryId,
    MediaType? type,
    String? url,
    String? thumbnailUrl,
    String? caption,
    String? uploadedByUid,
    String? uploadedByName,
    DateTime? uploadedAt,
    int? likes,
    List<String>? likedBy,
  }) {
    return GalleryMedia(
      id: id ?? this.id,
      galleryId: galleryId ?? this.galleryId,
      type: type ?? this.type,
      url: url ?? this.url,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      uploadedByUid: uploadedByUid ?? this.uploadedByUid,
      uploadedByName: uploadedByName ?? this.uploadedByName,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      likes: likes ?? this.likes,
      likedBy: likedBy ?? this.likedBy,
    );
  }

  bool isLikedBy(String uid) {
    return likedBy.contains(uid);
  }
}
