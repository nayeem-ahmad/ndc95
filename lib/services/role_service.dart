import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../models/user_role.dart';

/// Service to handle role-based permissions
class RoleService {
  /// Get user role from Firestore
  static Future<UserRole> getUserRole(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return UserRole.member;
      }

      final data = doc.data() as Map<String, dynamic>;
      final roleString = data['role'] as String?;
      return UserRoleExtension.fromString(roleString);
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.member;
    }
  }

  /// Get user's group from Firestore
  static Future<String?> getUserGroup(String uid) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return data['group'] as String?;
    } catch (e) {
      print('Error getting user group: $e');
      return null;
    }
  }

  /// Check if current user is superadmin
  static Future<bool> isSuperAdmin() async {
    final user = FirebaseService.currentUser;
    if (user == null) return false;
    
    // Check by email first (backward compatibility)
    if (user.email?.toLowerCase() == 'nayeem.ahmad@gmail.com') {
      return true;
    }
    
    // Check by role in database
    final role = await getUserRole(user.uid);
    return role == UserRole.superAdmin;
  }

  /// Check if current user is admin (or higher)
  static Future<bool> isAdmin() async {
    final user = FirebaseService.currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == UserRole.admin || role == UserRole.superAdmin;
  }

  /// Check if current user is group admin (or higher)
  static Future<bool> isGroupAdmin() async {
    final user = FirebaseService.currentUser;
    if (user == null) return false;
    
    final role = await getUserRole(user.uid);
    return role == UserRole.groupAdmin || 
           role == UserRole.admin || 
           role == UserRole.superAdmin;
  }

  /// Check if current user can edit a specific member
  static Future<bool> canEditMember(String targetUserId) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) return false;

    // User can always edit their own profile
    if (currentUser.uid == targetUserId) return true;

    final currentRole = await getUserRole(currentUser.uid);

    // Super admin and admin can edit anyone
    if (currentRole == UserRole.superAdmin || currentRole == UserRole.admin) {
      return true;
    }

    // Group admin can only edit members in their group
    if (currentRole == UserRole.groupAdmin) {
      final currentUserGroup = await getUserGroup(currentUser.uid);
      final targetUserGroup = await getUserGroup(targetUserId);
      
      return currentUserGroup != null && 
             currentUserGroup.isNotEmpty && 
             currentUserGroup == targetUserGroup;
    }

    return false;
  }

  /// Check if current user can delete a specific member
  static Future<bool> canDeleteMember(String targetUserId) async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) return false;

    // User cannot delete themselves
    if (currentUser.uid == targetUserId) return false;

    final currentRole = await getUserRole(currentUser.uid);

    // Super admin and admin can delete anyone
    if (currentRole == UserRole.superAdmin || currentRole == UserRole.admin) {
      return true;
    }

    // Group admin can only delete members in their group
    if (currentRole == UserRole.groupAdmin) {
      final currentUserGroup = await getUserGroup(currentUser.uid);
      final targetUserGroup = await getUserGroup(targetUserId);
      
      return currentUserGroup != null && 
             currentUserGroup.isNotEmpty && 
             currentUserGroup == targetUserGroup;
    }

    return false;
  }

  /// Check if current user can assign roles
  static Future<bool> canAssignRoles() async {
    final user = FirebaseService.currentUser;
    if (user == null) return false;
    
    // Only super admin can assign roles
    return await isSuperAdmin();
  }

  /// Update user role (only super admin can do this)
  static Future<void> updateUserRole({
    required String userId,
    required UserRole newRole,
  }) async {
    // Verify super admin permission
    final canAssign = await canAssignRoles();
    if (!canAssign) {
      throw Exception('Only super admin can assign roles');
    }

    await FirebaseService.firestore.collection('users').doc(userId).update({
      'role': newRole.value,
      'roleUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get members filtered by group (for group admin)
  static Stream<QuerySnapshot> getMembersByGroup(String group) {
    return FirebaseService.firestore
        .collection('users')
        .where('group', isEqualTo: group)
        .orderBy('displayName')
        .snapshots();
  }

  /// Get all members (for admin and super admin)
  static Stream<QuerySnapshot> getAllMembers() {
    return FirebaseService.firestore
        .collection('users')
        .orderBy('displayName')
        .snapshots();
  }

  /// Get filtered members based on current user's role
  static Future<Stream<QuerySnapshot>> getMembersForCurrentUser() async {
    final currentUser = FirebaseService.currentUser;
    if (currentUser == null) {
      throw Exception('User not logged in');
    }

    final role = await getUserRole(currentUser.uid);

    // Super admin and admin can see all members
    if (role == UserRole.superAdmin || role == UserRole.admin) {
      return getAllMembers();
    }

    // Group admin can only see their group members
    if (role == UserRole.groupAdmin) {
      final group = await getUserGroup(currentUser.uid);
      if (group == null || group.isEmpty) {
        throw Exception('Group admin must have a group assigned');
      }
      return getMembersByGroup(group);
    }

    // Regular members shouldn't have access to management
    throw Exception('Insufficient permissions');
  }
}
