import 'package:cloud_firestore/cloud_firestore.dart';

class Notice {
  final String id;
  final String title;
  final String summary;
  final String category;
  final DateTime visibleUntil;
  final DateTime createdAt;
  final String createdByUid;
  final String createdByName;
  final bool isPublished;
  final String? details;
  final DateTime? eventDate;
  final String? eventTime;
  final String? location;
  final String? rsvpLink;
  final String? contactPhone;
  final String? contactEmail;
  final String? bannerImageUrl;
  final List<String> attachments;
  final bool isPinned;

  const Notice({
    required this.id,
    required this.title,
    required this.summary,
    required this.category,
    required this.visibleUntil,
    required this.createdAt,
    required this.createdByUid,
    required this.createdByName,
    required this.isPublished,
    this.details,
    this.eventDate,
    this.eventTime,
    this.location,
    this.rsvpLink,
    this.contactPhone,
    this.contactEmail,
    this.bannerImageUrl,
    this.attachments = const [],
    this.isPinned = false,
  });

  Notice copyWith({
    String? id,
    String? title,
    String? summary,
    String? category,
    DateTime? visibleUntil,
    DateTime? createdAt,
    String? createdByUid,
    String? createdByName,
    bool? isPublished,
    String? details,
    DateTime? eventDate,
    String? eventTime,
    String? location,
    String? rsvpLink,
    String? contactPhone,
    String? contactEmail,
    String? bannerImageUrl,
    List<String>? attachments,
    bool? isPinned,
  }) {
    return Notice(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      category: category ?? this.category,
      visibleUntil: visibleUntil ?? this.visibleUntil,
      createdAt: createdAt ?? this.createdAt,
      createdByUid: createdByUid ?? this.createdByUid,
      createdByName: createdByName ?? this.createdByName,
      isPublished: isPublished ?? this.isPublished,
      details: details ?? this.details,
      eventDate: eventDate ?? this.eventDate,
      eventTime: eventTime ?? this.eventTime,
      location: location ?? this.location,
      rsvpLink: rsvpLink ?? this.rsvpLink,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      attachments: attachments ?? this.attachments,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  factory Notice.fromDocument(DocumentSnapshot doc) {
    final raw = doc.data();
    final data = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
    return Notice(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled notice',
      summary: data['summary'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      visibleUntil: _timestampToDate(data['visibleUntil']) ?? DateTime.now(),
      createdAt: _timestampToDate(data['createdAt']) ?? DateTime.now(),
      createdByUid: data['createdByUid'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? '',
      isPublished: data['isPublished'] as bool? ?? false,
      details: data['details'] as String?,
      eventDate: _timestampToDate(data['eventDate']),
      eventTime: data['eventTime'] as String?,
      location: data['location'] as String?,
      rsvpLink: data['rsvpLink'] as String?,
      contactPhone: data['contactPhone'] as String?,
      contactEmail: data['contactEmail'] as String?,
      bannerImageUrl: data['bannerImageUrl'] as String?,
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          const [],
      isPinned: data['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'summary': summary,
      'category': category,
      'visibleUntil': Timestamp.fromDate(visibleUntil),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdByUid': createdByUid,
      'createdByName': createdByName,
      'isPublished': isPublished,
      'details': details,
      'eventDate': eventDate != null ? Timestamp.fromDate(eventDate!) : null,
      'eventTime': eventTime,
      'location': location,
      'rsvpLink': rsvpLink,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'bannerImageUrl': bannerImageUrl,
      'attachments': attachments,
      'isPinned': isPinned,
    }..removeWhere((key, value) => value == null);
  }

  static DateTime? _timestampToDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
