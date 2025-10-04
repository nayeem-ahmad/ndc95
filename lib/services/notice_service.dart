import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/notice.dart';
import 'firebase_service.dart';

class NoticeService {
  static final _collection = FirebaseService.firestore.collection('notices');

  static Stream<List<Notice>> streamActiveNotices() {
    return _collection
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final notices = snapshot.docs
              .map(Notice.fromDocument)
              .where((notice) => !notice.visibleUntil.isBefore(now))
              .toList();
          notices.sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            final aDate = a.eventDate ?? a.visibleUntil;
            final bDate = b.eventDate ?? b.visibleUntil;
            return aDate.compareTo(bDate);
          });
          return notices;
        });
  }

  static Stream<List<Notice>> streamAllNotices() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Notice.fromDocument).toList());
  }

  static Future<Notice?> fetchNotice(String id) async {
    final doc = await _collection.doc(id).get();
    if (!doc.exists) return null;
    return Notice.fromDocument(doc);
  }

  static Future<String> createNotice(Notice notice) async {
    final data = notice.toMap();
    final doc = await _collection.add(data);
    return doc.id;
  }

  static Future<void> updateNotice(Notice notice) async {
    await _collection.doc(notice.id).update(notice.toMap());
  }

  static Future<void> deleteNotice(String id) async {
    await _collection.doc(id).delete();
  }

  static Future<void> setPublished(String id, bool isPublished) async {
    await _collection.doc(id).update({'isPublished': isPublished});
  }

  static Future<({int processed, int unpublished, int deleted})>
  cleanupExpiredNotices({bool deleteExpired = false}) async {
    final now = Timestamp.fromDate(DateTime.now());
    final snapshot = await _collection
        .where('visibleUntil', isLessThan: now)
        .get();

    var unpublished = 0;
    var deleted = 0;

    for (final doc in snapshot.docs) {
      if (deleteExpired) {
        await doc.reference.delete();
        deleted++;
      } else {
        final data = doc.data();
        final isCurrentlyPublished = (data['isPublished'] as bool?) ?? false;
        if (isCurrentlyPublished) {
          await doc.reference.update({'isPublished': false});
          unpublished++;
        }
      }
    }

    return (
      processed: snapshot.docs.length,
      unpublished: unpublished,
      deleted: deleted,
    );
  }

  static Future<String?> uploadBannerImage({
    required Uint8List data,
    required String fileName,
    String? contentType,
  }) async {
    final uniqueName =
        'banner_${DateTime.now().millisecondsSinceEpoch}_$fileName';
    return FirebaseService.uploadNoticeBanner(
      data: data,
      fileName: uniqueName,
      contentType: contentType,
    );
  }
}
