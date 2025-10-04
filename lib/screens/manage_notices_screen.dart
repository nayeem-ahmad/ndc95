import 'package:flutter/material.dart';

import '../models/notice.dart';
import '../models/user_role.dart';
import '../services/firebase_service.dart';
import '../services/notice_service.dart';
import '../services/role_service.dart';
import '../widgets/notice_editor_dialog.dart';

class ManageNoticesScreen extends StatefulWidget {
  const ManageNoticesScreen({super.key});

  @override
  State<ManageNoticesScreen> createState() => _ManageNoticesScreenState();
}

enum _CleanupAction { unpublish, delete }

class _ManageNoticesScreenState extends State<ManageNoticesScreen> {
  bool _isLoadingRole = true;
  bool _isAuthorized = false;
  bool _isCleaning = false;

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final user = FirebaseService.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingRole = false;
        _isAuthorized = false;
      });
      return;
    }

    final role = await RoleService.getUserRole(user.uid);
    final allowed = role == UserRole.admin || role == UserRole.superAdmin;

    if (!mounted) return;
    setState(() {
      _isAuthorized = allowed;
      _isLoadingRole = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Manage Notices'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 56,
                  color: Colors.blueGrey.shade200,
                ),
                const SizedBox(height: 16),
                Text(
                  'You do not have permission to manage notices.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please contact an administrator if you believe this is a mistake.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Notices'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Clean up expired notices',
            onPressed: _isCleaning ? null : _handleCleanupExpired,
            icon: _isCleaning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.cleaning_services_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleCreateNotice,
        icon: const Icon(Icons.add),
        label: const Text('New Notice'),
      ),
      body: StreamBuilder<List<Notice>>(
        stream: NoticeService.streamAllNotices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorState(message: snapshot.error.toString());
          }

          final notices = snapshot.data ?? [];
          if (notices.isEmpty) {
            return const _EmptyState();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: notices.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final notice = notices[index];
              return _NoticeCard(
                notice: notice,
                onEdit: () => _handleEditNotice(notice),
                onDelete: () => _handleDeleteNotice(notice),
                onTogglePublish: (value) =>
                    NoticeService.setPublished(notice.id, value),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleCleanupExpired() async {
    final action = await showDialog<_CleanupAction>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clean up expired notices'),
        content: const Text(
          'What would you like to do with notices that have already expired?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(_CleanupAction.unpublish),
            child: const Text('Unpublish'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_CleanupAction.delete),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (action == null) return;

    setState(() => _isCleaning = true);

    try {
      final result = await NoticeService.cleanupExpiredNotices(
        deleteExpired: action == _CleanupAction.delete,
      );

      if (!mounted) return;

      final message = result.processed == 0
          ? 'No expired notices found.'
          : action == _CleanupAction.delete
          ? 'Removed ${result.deleted} expired notice${result.deleted == 1 ? '' : 's'}.'
          : 'Unpublished ${result.unpublished} expired notice${result.unpublished == 1 ? '' : 's'}.';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cleanup failed: $error'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCleaning = false);
      }
    }
  }

  Future<void> _handleCreateNotice() async {
    final currentUser = FirebaseService.currentUser;
    final createdByName =
        currentUser?.displayName ?? currentUser?.email ?? 'Unknown';

    final draft = Notice(
      id: '',
      title: '',
      summary: '',
      category: 'General',
      visibleUntil: DateTime.now().add(const Duration(days: 7)),
      createdAt: DateTime.now(),
      createdByUid: currentUser?.uid ?? '',
      createdByName: createdByName,
      isPublished: false,
    );

    final result = await showNoticeEditorDialog(
      context: context,
      initialNotice: draft,
    );
    if (result == null) return;

    await NoticeService.createNotice(result);
  }

  Future<void> _handleEditNotice(Notice notice) async {
    final result = await showNoticeEditorDialog(
      context: context,
      initialNotice: notice,
    );
    if (result == null) return;

    await NoticeService.updateNotice(result.copyWith(id: notice.id));
  }

  Future<void> _handleDeleteNotice(Notice notice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete notice?'),
        content: Text('"${notice.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await NoticeService.deleteNotice(notice.id);
  }
}

class _NoticeCard extends StatelessWidget {
  final Notice notice;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onTogglePublish;

  const _NoticeCard({
    required this.notice,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePublish,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpired = notice.visibleUntil.isBefore(DateTime.now());

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (notice.bannerImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 3 / 1.4,
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
              const SizedBox(height: 12),
            ],
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
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
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              notice.category,
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (notice.isPinned) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.push_pin,
                              size: 18,
                              color: Colors.orange.shade600,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        notice.title.isNotEmpty
                            ? notice.title
                            : '(No title yet)',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notice.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            icon: Icons.calendar_today,
                            label:
                                'Visible till ${_formatDate(notice.visibleUntil)}',
                          ),
                          if (notice.eventDate != null)
                            _InfoChip(
                              icon: Icons.event,
                              label: 'Event ${_formatDate(notice.eventDate!)}',
                            ),
                          if (notice.eventTime != null &&
                              notice.eventTime!.isNotEmpty)
                            _InfoChip(
                              icon: Icons.schedule,
                              label: notice.eventTime!,
                            ),
                          if (notice.location != null &&
                              notice.location!.isNotEmpty)
                            _InfoChip(
                              icon: Icons.location_on_outlined,
                              label: notice.location!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: notice.isPublished && !isExpired,
                  onChanged: isExpired ? null : onTogglePublish,
                  thumbColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green.shade600;
                    }
                    return Colors.grey.shade400;
                  }),
                  trackColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.green.shade200;
                    }
                    return Colors.grey.shade200;
                  }),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade600,
                  ),
                  label: const Text('Delete'),
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Created by ${notice.createdByName} · ${_formatDateTime(notice.createdAt)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            if (isExpired)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Expired',
                  style: TextStyle(
                    color: Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final timeOfDay = TimeOfDay.fromDateTime(dateTime);
    final hour = timeOfDay.hourOfPeriod == 0 ? 12 : timeOfDay.hourOfPeriod;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = timeOfDay.period == DayPeriod.am ? 'AM' : 'PM';
    final time = '$hour:$minute $period';
    return '$date • $time';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: Colors.grey.shade800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement_outlined,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No notices posted yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap “New Notice” to get started.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;

  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 56, color: Colors.red.shade400),
            const SizedBox(height: 12),
            Text(
              'Unable to load notices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
