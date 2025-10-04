import 'package:cloud_firestore/cloud_firestore.dart';

class Gallery {
  final String id;
  final String title;
  final String description;
  final DateTime occasionDate;
  final String? coverImageUrl;
  final String createdByUid;
  final String createdByName;
  final DateTime createdAt;
  final bool isPublished;
  final int contributorsCount;
  final int mediaCount;
  final List<String> tags;

  Gallery({
    required this.id,
    required this.title,
    required this.description,
    required this.occasionDate,
    this.coverImageUrl,
    required this.createdByUid,
    required this.createdByName,
    required this.createdAt,
    required this.isPublished,
    this.contributorsCount = 0,
    this.mediaCount = 0,
    this.tags = const [],
  });

  factory Gallery.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Gallery(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      occasionDate: (data['occasionDate'] as Timestamp).toDate(),
      coverImageUrl: data['coverImageUrl'],
      createdByUid: data['createdByUid'] ?? '',
      createdByName: data['createdByName'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isPublished: data['isPublished'] ?? false,
      contributorsCount: data['contributorsCount'] ?? 0,
      mediaCount: data['mediaCount'] ?? 0,
      tags: List<String>.from(data['tags'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'occasionDate': Timestamp.fromDate(occasionDate),
      'coverImageUrl': coverImageUrl,
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isPublished': isPublished,
      'contributorsCount': contributorsCount,
      'mediaCount': mediaCount,
      'tags': tags,
    };
  }

  Gallery copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? occasionDate,
    String? coverImageUrl,
    String? createdByUid,
    String? createdByName,
    DateTime? createdAt,
    bool? isPublished,
    int? contributorsCount,
    int? mediaCount,
    List<String>? tags,
  }) {
    return Gallery(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      occasionDate: occasionDate ?? this.occasionDate,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      isPublished: isPublished ?? this.isPublished,
      contributorsCount: contributorsCount ?? this.contributorsCount,
      mediaCount: mediaCount ?? this.mediaCount,
      tags: tags ?? this.tags,
    );
  }
}
