import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';
import '../widgets/role_assignment_dialog.dart';
import 'member_form_screen.dart';

class ManageMembersScreen extends StatefulWidget {
  const ManageMembersScreen({super.key});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _canAssignRoles = false;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    final canAssign = await RoleService.canAssignRoles();
    setState(() {
      _canAssignRoles = canAssign;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteMember(String userId, String userName) async {
    // Check permission
    final canDelete = await RoleService.canDeleteMember(userId);
    if (!canDelete) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You do not have permission to delete this member'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
          'Are you sure you want to delete "$userName"?\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseService.firestore.collection('users').doc(userId).delete();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Member deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting member: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _addOrEditMember({String? userId, Map<String, dynamic>? userData}) async {
    // Check edit permission if editing
    if (userId != null) {
      final canEdit = await RoleService.canEditMember(userId);
      if (!canEdit) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You do not have permission to edit this member'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => MemberFormScreen(
          userId: userId,
          userData: userData,
        ),
      ),
    );

    // Refresh the list if changes were made
    if (result == true && mounted) {
      setState(() {}); // Trigger rebuild to refresh StreamBuilder
    }
  }

  Future<void> _assignRole(String userId, String userName, Map<String, dynamic> userData) async {
    final currentRoleString = userData['role'] as String?;
    final currentRole = UserRoleExtension.fromString(currentRoleString);
    final userGroup = userData['group'] as String?;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => RoleAssignmentDialog(
        userId: userId,
        userName: userName,
        currentRole: currentRole,
        userGroup: userGroup,
      ),
    );

    if (result == true && mounted) {
      setState(() {}); // Refresh to show updated role
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
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
        child: Column(
          children: [
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by name or email...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),

            // Members List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseService.firestore
                    .collection('users')
                    .orderBy('displayName')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading members',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Filter users based on search query
                  final users = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['displayName']?.toString().toLowerCase() ?? '';
                    final email = data['email']?.toString().toLowerCase() ?? '';

                    if (_searchQuery.isEmpty) return true;
                    return name.contains(_searchQuery) || email.contains(_searchQuery);
                  }).toList();

                  if (users.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.person_off, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? 'No members found' : 'No results found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      // Count Badge
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue.shade200, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people, size: 18, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              '${users.length} ${users.length == 1 ? 'member' : 'members'}',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Text(
                                'found',
                                style: TextStyle(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Members List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: users.length,
                          itemBuilder: (context, index) {
                            final doc = users[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final userId = doc.id;
                            final name = data['displayName'] ?? 'Unknown';
                            final email = data['email'] ?? '';
                            final studentId = data['studentId'] ?? '';
                            final photoUrl = data['photoUrl'] ?? '';
                            final roleString = data['role'] as String?;
                            final role = UserRoleExtension.fromString(roleString);

                            // Determine role badge color
                            Color getRoleBadgeColor() {
                              switch (role) {
                                case UserRole.superAdmin:
                                  return Colors.red;
                                case UserRole.admin:
                                  return Colors.orange;
                                case UserRole.groupAdmin:
                                  return Colors.green;
                                case UserRole.member:
                                  return Colors.grey;
                              }
                            }

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: Colors.blue.shade100,
                                      backgroundImage: photoUrl.isNotEmpty
                                          ? NetworkImage(photoUrl)
                                          : null,
                                      child: photoUrl.isEmpty
                                          ? Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                            )
                                          : null,
                                    ),
                                    if (role != UserRole.member)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: getRoleBadgeColor(),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            role == UserRole.superAdmin
                                                ? Icons.admin_panel_settings
                                                : role == UserRole.admin
                                                    ? Icons.manage_accounts
                                                    : Icons.supervisor_account,
                                            size: 12,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    if (role != UserRole.member)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: getRoleBadgeColor().withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: getRoleBadgeColor(),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          role.displayName,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: getRoleBadgeColor(),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (email.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.email, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              email,
                                              style: TextStyle(
                                                color: Colors.grey.shade700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    if (studentId.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          const Icon(Icons.badge, size: 14, color: Colors.grey),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ID: $studentId',
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_canAssignRoles)
                                      IconButton(
                                        icon: Icon(
                                          Icons.admin_panel_settings,
                                          color: Colors.purple.shade700,
                                        ),
                                        onPressed: () => _assignRole(userId, name, data),
                                        tooltip: 'Assign Role',
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue),
                                      onPressed: () => _addOrEditMember(
                                        userId: userId,
                                        userData: data,
                                      ),
                                      tooltip: 'Edit',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteMember(userId, name),
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEditMember(),
        icon: const Icon(Icons.add),
        label: const Text('Add Member'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }
}
