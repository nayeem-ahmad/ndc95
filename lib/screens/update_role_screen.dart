import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';

class UpdateRoleScreen extends StatefulWidget {
  const UpdateRoleScreen({super.key});

  @override
  State<UpdateRoleScreen> createState() => _UpdateRoleScreenState();
}

class _UpdateRoleScreenState extends State<UpdateRoleScreen> {
  bool _isUpdating = false;
  String? _message;

  Future<void> _updateRole() async {
    setState(() {
      _isUpdating = true;
      _message = null;
    });

    try {
      final user = FirebaseService.currentUser;
      if (user == null) {
        throw 'No user signed in';
      }

      // Update role to superadmin
      await FirebaseService.firestore
          .collection('users')
          .doc(user.uid)
          .set({
        'role': 'superadmin',
      }, SetOptions(merge: true));

      setState(() {
        _message = '✅ Successfully updated role to superadmin!\n\nYou can now import CSV files.';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Role to Superadmin'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current User',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Email: ${user?.email ?? 'Not signed in'}'),
                    Text('UID: ${user?.uid ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.black87),
                        SizedBox(width: 8),
                        Text(
                          'One-Time Setup',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This will update your user role to "superadmin" which is required for CSV import and admin features.',
                      style: TextStyle(color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUpdating || user == null ? null : _updateRole,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              icon: _isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.admin_panel_settings),
              label: Text(
                _isUpdating ? 'Updating...' : 'Update to Superadmin',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            if (_message != null) ...[
              const SizedBox(height: 24),
              Card(
                color: _message!.startsWith('✅')
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('✅')
                          ? Colors.green.shade900
                          : Colors.red.shade900,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
