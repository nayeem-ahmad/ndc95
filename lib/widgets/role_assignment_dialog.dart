import 'package:flutter/material.dart';
import '../models/user_role.dart';
import '../services/role_service.dart';

class RoleAssignmentDialog extends StatefulWidget {
  final String userId;
  final String userName;
  final UserRole currentRole;
  final String? userGroup;

  const RoleAssignmentDialog({
    super.key,
    required this.userId,
    required this.userName,
    required this.currentRole,
    this.userGroup,
  });

  @override
  State<RoleAssignmentDialog> createState() => _RoleAssignmentDialogState();
}

class _RoleAssignmentDialogState extends State<RoleAssignmentDialog> {
  late UserRole _selectedRole;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  Future<void> _assignRole() async {
    if (_selectedRole == widget.currentRole) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await RoleService.updateUserRole(
        userId: widget.userId,
        newRole: _selectedRole,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Role updated to ${_selectedRole.displayName} for ${widget.userName}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assign Role'),
          const SizedBox(height: 4),
          Text(
            widget.userName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.normal,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.userGroup != null && widget.userGroup!.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.group, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Group ${widget.userGroup}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Text(
              'Select a role:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...UserRole.values.map((role) => _buildRoleOption(role)).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _assignRole,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade700,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Text('Assign Role'),
        ),
      ],
    );
  }

  Widget _buildRoleOption(UserRole role) {
    final isSelected = _selectedRole == role;
    
    Color getColor() {
      switch (role) {
        case UserRole.superAdmin:
          return Colors.red.shade700;
        case UserRole.admin:
          return Colors.orange.shade700;
        case UserRole.groupAdmin:
          return Colors.green.shade700;
        case UserRole.member:
          return Colors.blue.shade700;
      }
    }

    IconData getIcon() {
      switch (role) {
        case UserRole.superAdmin:
          return Icons.admin_panel_settings;
        case UserRole.admin:
          return Icons.manage_accounts;
        case UserRole.groupAdmin:
          return Icons.supervisor_account;
        case UserRole.member:
          return Icons.person;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? getColor().withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: _isSaving ? null : () {
            setState(() {
              _selectedRole = role;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? getColor() : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Radio<UserRole>(
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: _isSaving ? null : (value) {
                    if (value != null) {
                      setState(() {
                        _selectedRole = value;
                      });
                    }
                  },
                  activeColor: getColor(),
                ),
                Icon(
                  getIcon(),
                  color: getColor(),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? getColor() : Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
