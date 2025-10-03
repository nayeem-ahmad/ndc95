import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

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
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeBanner(name: greetingName),
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

    return sorted
        .map((entry) {
          final rawKey = entry.key;
          String? normalized;
          if (rawKey != 'Not set') {
            final stripped = rawKey.replaceAll(RegExp('^group\\s*', caseSensitive: false), '').trim();
            if (stripped.isNotEmpty) {
              normalized = stripped;
            }
          }

          final display = normalized == null ? 'Not Assigned' : _formatGroupLabel(normalized);

          return _StatsItem(
            value: normalized,
            display: display,
            count: entry.value,
          );
        })
        .toList();
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

    return sorted
        .map((entry) {
          final key = entry.key;
          final normalized = key == 'Not set' ? null : key;
          return _StatsItem(
            value: normalized,
            display: normalized ?? 'Not set',
            count: entry.value,
          );
        })
        .toList();
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

  const _StatsItem({required this.value, required this.display, required this.count});
}

class _WelcomeBanner extends StatelessWidget {
  final String name;

  const _WelcomeBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade700,
            Colors.blue.shade400,
          ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
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
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
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

  const _StatChip({
    required this.item,
    required this.accentColor,
    this.onTap,
  });

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 12),
            Text(
              'No members yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Once members are added, you will see group, profession, and home district insights here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load insights',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
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
