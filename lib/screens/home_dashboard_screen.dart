import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/notice.dart';
import '../services/firebase_service.dart';
import '../services/notice_service.dart';

class HomeDashboardScreen extends StatelessWidget {
  final void Function(String group)? onGroupSelected;

  const HomeDashboardScreen({super.key, this.onGroupSelected});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;
    final rawName = user?.displayName?.trim();
    final greetingName = (rawName != null && rawName.isNotEmpty)
        ? rawName.split(' ').first
        : 'NDC95 Member';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBanner(name: greetingName),
            const SizedBox(height: 20),
            const _NoticeCarousel(),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseService.firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _SectionSkeleton();
                }

                if (snapshot.hasError) {
                  return _ErrorSection(error: snapshot.error.toString());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const _EmptyStateSection();
                }

                final groupCounts = _buildCountMap(docs, 'group');
                final professionCounts = _buildCountMap(docs, 'profession');
                final districtCounts = _buildCountMap(docs, 'homeDistrict');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatsSection(
                      title: 'Groups at a Glance',
                      subtitle: 'Track member distribution across groups',
                      icon: Icons.groups,
                      accentColor: Colors.indigo,
                      items: _formatGroupEntries(groupCounts),
                      onItemTap: (item) {
                        final value = item.value;
                        if (value != null && value.isNotEmpty) {
                          onGroupSelected?.call(value);
                        }
                      },
                    ),
                    const SizedBox(height: 20),
                    _StatsSection(
                      title: 'Professions Spotlight',
                      subtitle: 'See the professional diversity of the alumni',
                      icon: Icons.work_outline,
                      accentColor: Colors.teal,
                      items: _formatEntries(professionCounts),
                    ),
                    const SizedBox(height: 20),
                    _StatsSection(
                      title: 'Home District Highlights',
                      subtitle: 'Where our members call home',
                      icon: Icons.location_on_outlined,
                      accentColor: Colors.deepOrange,
                      items: _formatEntries(districtCounts),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static Map<String, int> _buildCountMap(
    List<QueryDocumentSnapshot<Object?>> docs,
    String field,
  ) {
    final map = <String, int>{};
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final raw = data[field];
      String value = '';
      if (raw is String) {
        value = raw.trim();
      } else if (raw != null) {
        value = raw.toString().trim();
      }
      if (value.isEmpty) {
        value = 'Not set';
      }
      map[value] = (map[value] ?? 0) + 1;
    }
    return map;
  }

  static List<_StatsItem> _formatGroupEntries(Map<String, int> counts) {
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Not set') return 1;
        if (b.key == 'Not set') return -1;
        final valueCompare = b.value.compareTo(a.value);
        if (valueCompare != 0) return valueCompare;
        return a.key.compareTo(b.key);
      });

    return sorted.map((entry) {
      final rawKey = entry.key;
      String? normalized;
      if (rawKey != 'Not set') {
        final stripped = rawKey
            .replaceAll(RegExp('^group\\s*', caseSensitive: false), '')
            .trim();
        if (stripped.isNotEmpty) {
          normalized = stripped;
        }
      }

      final display = normalized == null
          ? 'Not Assigned'
          : _formatGroupLabel(normalized);

      return _StatsItem(
        value: normalized,
        display: display,
        count: entry.value,
      );
    }).toList();
  }

  static List<_StatsItem> _formatEntries(Map<String, int> counts) {
    final sorted = counts.entries.toList()
      ..sort((a, b) {
        if (a.key == 'Not set') return 1;
        if (b.key == 'Not set') return -1;
        final valueCompare = b.value.compareTo(a.value);
        if (valueCompare != 0) return valueCompare;
        return a.key.compareTo(b.key);
      });

    return sorted.map((entry) {
      final key = entry.key;
      final normalized = key == 'Not set' ? null : key;
      return _StatsItem(
        value: normalized,
        display: normalized ?? 'Not set',
        count: entry.value,
      );
    }).toList();
  }

  static String _formatGroupLabel(String raw) {
    final lower = raw.toLowerCase();
    if (lower.startsWith('group')) {
      return raw;
    }
    return 'Group $raw';
  }
}

class _StatsItem {
  final String? value;
  final String display;
  final int count;

  const _StatsItem({
    required this.value,
    required this.display,
    required this.count,
  });
}

class _NoticeCarousel extends StatelessWidget {
  const _NoticeCarousel();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Notice>>(
      stream: NoticeService.streamActiveNotices(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _NoticeCarouselSkeleton();
        }

        if (snapshot.hasError) {
          debugPrint('Notice stream error: ${snapshot.error}');
          return _NoticeCarouselError(message: snapshot.error.toString());
        }

        final notices = snapshot.data ?? [];
        if (notices.isEmpty) {
          return const SizedBox.shrink();
        }

        final items = [...notices]
          ..sort((a, b) {
            if (a.isPinned != b.isPinned) {
              return a.isPinned ? -1 : 1;
            }
            final aDate = a.eventDate ?? a.visibleUntil;
            final bDate = b.eventDate ?? b.visibleUntil;
            return aDate.compareTo(bDate);
          });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    color: Colors.deepPurple,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notices & Upcoming Events',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stay in the loop with the latest announcements and events.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (context, index) {
                  final notice = items[index];
                  return _NoticeBannerCard(
                    notice: notice,
                    onTap: () => _showNoticeDetails(context, notice),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNoticeDetails(BuildContext context, Notice notice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    notice.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _DetailChip(
                        icon: Icons.category_outlined,
                        label: notice.category,
                      ),
                      const SizedBox(width: 8),
                      _DetailChip(
                        icon: Icons.access_time,
                        label:
                            'Visible till ${_formatDate(notice.visibleUntil)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (notice.bannerImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 3 / 1.2,
                        child: Image.network(
                          notice.bannerImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text(
                    notice.summary,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade800,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (notice.details != null && notice.details!.isNotEmpty) ...[
                    Text(
                      notice.details!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (notice.eventDate != null)
                    _DetailRow(
                      icon: Icons.event,
                      label: 'Event date',
                      value: _formatDate(notice.eventDate!),
                    ),
                  if (notice.eventTime != null && notice.eventTime!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.schedule,
                      label: 'Time',
                      value: notice.eventTime!,
                    ),
                  if (notice.location != null && notice.location!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.location_on_outlined,
                      label: 'Location',
                      value: notice.location!,
                    ),
                  if (notice.rsvpLink != null && notice.rsvpLink!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.link,
                      label: 'RSVP / Link',
                      value: notice.rsvpLink!,
                    ),
                  if (notice.contactPhone != null &&
                      notice.contactPhone!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.phone_outlined,
                      label: 'Contact phone',
                      value: notice.contactPhone!,
                    ),
                  if (notice.contactEmail != null &&
                      notice.contactEmail!.isNotEmpty)
                    _DetailRow(
                      icon: Icons.email_outlined,
                      label: 'Contact email',
                      value: notice.contactEmail!,
                    ),
                  const SizedBox(height: 20),
                  Text(
                    'Posted by ${notice.createdByName} • ${_formatDateTime(notice.createdAt)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final timeOfDay = TimeOfDay.fromDateTime(dateTime);
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    return '$date • $hour:$minute $period';
  }
}

class _NoticeBannerCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onTap;

  const _NoticeBannerCard({required this.notice, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width < 400 ? width - 60 : 280.0;
    final gradientColors = notice.isPinned
        ? [Colors.orange.shade600, Colors.deepOrange.shade400]
        : [Colors.blue.shade600, Colors.blue.shade300];

    return SizedBox(
      width: cardWidth,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                if (notice.bannerImageUrl != null)
                  Positioned.fill(
                    child: Image.network(
                      notice.bannerImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: notice.bannerImageUrl != null
                            ? [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.black.withValues(alpha: 0.15),
                              ]
                            : gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              notice.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (notice.isPinned) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.push_pin,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        notice.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.summary,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.3,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            notice.eventDate != null
                                ? _NoticeCarousel._formatDate(notice.eventDate!)
                                : 'Till ${_NoticeCarousel._formatDate(notice.visibleUntil)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NoticeCarouselSkeleton extends StatelessWidget {
  const _NoticeCarouselSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          width: 210,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 170,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (_, __) => Container(
              width: 280,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemCount: 3,
          ),
        ),
      ],
    );
  }
}

class _NoticeCarouselError extends StatelessWidget {
  final String message;

  const _NoticeCarouselError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Unable to load notices: $message',
              style: TextStyle(color: Colors.red.shade600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: Colors.blueGrey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: Colors.grey.shade800, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final String name;

  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.home_filled,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Your alumni community at a glance. Keep exploring, connecting, and growing together with NDC95.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<_StatsItem> items;
  final void Function(_StatsItem item)? onItemTap;

  const _StatsSection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No data available yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 10.0;
                  final availableWidth = constraints.maxWidth;
                  final itemWidth = availableWidth > spacing
                      ? (availableWidth - spacing) / 2
                      : availableWidth;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: spacing,
                    children: items
                        .map(
                          (item) => SizedBox(
                            width: itemWidth,
                            child: _StatChip(
                              item: item,
                              accentColor: accentColor,
                              onTap: onItemTap != null && item.value != null
                                  ? () => onItemTap!(item)
                                  : null,
                            ),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final _StatsItem item;
  final Color accentColor;
  final VoidCallback? onTap;

  const _StatChip({required this.item, required this.accentColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(32),
        child: Container(
          constraints: const BoxConstraints(minWidth: 110, maxWidth: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: accentColor.withValues(alpha: 0.2)),
          ),
          alignment: Alignment.center,
          child: Text(
            '${item.display} (${item.count})',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: accentColor.darken(),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionSkeleton extends StatelessWidget {
  const _SectionSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShimmerBlock(height: 160),
        const SizedBox(height: 20),
        _ShimmerBlock(height: 220),
        const SizedBox(height: 20),
        _ShimmerBlock(height: 220),
        const SizedBox(height: 20),
        _ShimmerBlock(height: 220),
      ],
    );
  }
}

class _ShimmerBlock extends StatelessWidget {
  final double height;

  const _ShimmerBlock({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade500),
            const SizedBox(height: 12),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Once members are added, you will see group, profession, and home district insights here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorSection extends StatelessWidget {
  final String error;

  const _ErrorSection({required this.error});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              'Unable to load insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = 0.15]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
