import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/role_service.dart';
import '../models/user_role.dart';
import 'manage_members_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  bool _isFixingGroups = false;
  String? _resultMessage;
  int _totalRecords = 0;
  int _updatedRecords = 0;
  int _skippedRecords = 0;
  UserRole? _currentUserRole;
  String? _currentUserGroup;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    final user = FirebaseService.currentUser;
    if (user != null) {
      final role = await RoleService.getUserRole(user.uid);
      final group = await RoleService.getUserGroup(user.uid);
      setState(() {
        _currentUserRole = role;
        _currentUserGroup = group;
        _isLoadingRole = false;
      });
    }
  }

  // Helper method to extract group from student ID (3rd digit)
  String _getGroupFromStudentId(String? studentId) {
    if (studentId == null || studentId.length < 3) {
      return '';
    }
    return studentId.substring(2, 3); // Get the 3rd character (index 2)
  }

  Future<void> _fixGroupFields() async {
    setState(() {
      _isFixingGroups = true;
      _resultMessage = null;
      _totalRecords = 0;
      _updatedRecords = 0;
      _skippedRecords = 0;
    });

    try {
      // Get all users from Firestore
      final QuerySnapshot snapshot =
          await FirebaseService.firestore.collection('users').get();

      _totalRecords = snapshot.docs.length;

      // Update each user's group field based on their studentId
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final studentId = data['studentId']?.toString();
        final currentGroup = data['group']?.toString();
        final calculatedGroup = _getGroupFromStudentId(studentId);

        // Debug logging
        print('Processing user: ${data['displayName']}, StudentID: $studentId, CurrentGroup: "$currentGroup", CalculatedGroup: "$calculatedGroup"');

        // Only update if group is missing or different from calculated value
        if (currentGroup != calculatedGroup) {
          await doc.reference.update({
            'group': calculatedGroup,
            'groupFixedAt': FieldValue.serverTimestamp(),
          });
          _updatedRecords++;
          print('  ✓ Updated group to "$calculatedGroup"');
        } else {
          _skippedRecords++;
          print('  - Skipped (already correct)');
        }
      }

      setState(() {
        _isFixingGroups = false;
        _resultMessage =
            'Successfully processed $_totalRecords records.\n'
            'Updated: $_updatedRecords\n'
            'Already correct: $_skippedRecords';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group fields updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isFixingGroups = false;
        _resultMessage = 'Error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating groups: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    final isSuperAdmin = _currentUserRole == UserRole.superAdmin;
    final isAdmin = _currentUserRole == UserRole.admin || isSuperAdmin;
    final isGroupAdmin = _currentUserRole == UserRole.groupAdmin;

    String getManageMembersTitle() {
      if (isSuperAdmin || isAdmin) {
        return 'Manage All Members';
      } else if (isGroupAdmin) {
        return 'Manage Group ${_currentUserGroup ?? ''} Members';
      }
      return 'Manage Members';
    }

    String getManageMembersDescription() {
      if (isSuperAdmin) {
        return 'Add new members, edit existing member information, delete members, and assign roles (Super Admin, Admin, Group Admin).';
      } else if (isAdmin) {
        return 'Add new members, edit existing member information, and delete members from the directory.';
      } else if (isGroupAdmin) {
        return 'Add new members to Group ${_currentUserGroup ?? ''}, edit member information, and delete members in your group.';
      }
      return 'Manage members in the directory.';
    }

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Admin Tools Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.blue.shade700,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Admin Tools',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Administrative tools and utilities',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamed('/update-role');
                            },
                            icon: const Icon(Icons.admin_panel_settings),
                            label: const Text(
                              'Update Role to Superadmin',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        if (isSuperAdmin) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamed('/admin-import');
                              },
                              icon: const Icon(Icons.upload_file),
                              label: const Text(
                                'Import Members from CSV',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo.shade600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Current Role Information
            if (_currentUserRole != null) ...[
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _currentUserRole == UserRole.superAdmin
                                ? Icons.admin_panel_settings
                                : _currentUserRole == UserRole.admin
                                    ? Icons.manage_accounts
                                    : Icons.supervisor_account,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Your Role',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _currentUserRole!.displayName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentUserRole!.description,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.purple.shade700,
                                    ),
                                  ),
                                  if (_currentUserGroup != null && _currentUserGroup!.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.group,
                                          size: 16,
                                          color: Colors.purple.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Group ${_currentUserGroup}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.purple.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Manage Members Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            getManageMembersTitle(),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      getManageMembersDescription(),
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Manage Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ManageMembersScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.manage_accounts),
                        label: const Text(
                          'Manage Members',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Fix Group Fields Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          color: Colors.orange.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Fix Group Fields',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This will update the "group" field for all users based on their Student ID (3rd digit). '
                      'Only records with missing or incorrect group values will be updated.',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Warning box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This operation will update multiple records. Make sure you have a backup.',
                              style: TextStyle(
                                color: Colors.orange.shade900,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Fix Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isFixingGroups ? null : _fixGroupFields,
                        icon: _isFixingGroups
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.build),
                        label: Text(
                          _isFixingGroups ? 'Fixing...' : 'Fix Group Fields',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    // Result Message
                    if (_resultMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _resultMessage!.startsWith('Error')
                              ? Colors.red.shade50
                              : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _resultMessage!.startsWith('Error')
                                ? Colors.red.shade200
                                : Colors.green.shade200,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _resultMessage!.startsWith('Error')
                                  ? Icons.error_outline
                                  : Icons.check_circle_outline,
                              color: _resultMessage!.startsWith('Error')
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _resultMessage!,
                                style: TextStyle(
                                  color: _resultMessage!.startsWith('Error')
                                      ? Colors.red.shade900
                                      : Colors.green.shade900,
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Info Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      '1. Reads all user records from Firestore',
                    ),
                    _buildInfoItem(
                      '2. Extracts the 3rd digit from each Student ID',
                    ),
                    _buildInfoItem(
                      '3. Updates the group field if it\'s missing or incorrect',
                    ),
                    _buildInfoItem(
                      '4. Skips records that already have the correct group',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Example: Student ID "95301" → Group "3"',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: 16,
            color: Colors.green.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
