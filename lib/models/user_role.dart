/// User role enumeration
enum UserRole {
  member,      // Regular member (default)
  groupAdmin,  // Can manage members in their group
  admin,       // Can manage all members except roles
  superAdmin,  // Can do everything including role management
}

/// Extension to convert role to/from string
extension UserRoleExtension on UserRole {
  String get value {
    switch (this) {
      case UserRole.member:
        return 'member';
      case UserRole.groupAdmin:
        return 'groupAdmin';
      case UserRole.admin:
        return 'admin';
      case UserRole.superAdmin:
        return 'superAdmin';
    }
  }

  static UserRole fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'groupadmin':
        return UserRole.groupAdmin;
      case 'admin':
        return UserRole.admin;
      case 'superadmin':
        return UserRole.superAdmin;
      default:
        return UserRole.member;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.member:
        return 'Member';
      case UserRole.groupAdmin:
        return 'Group Admin';
      case UserRole.admin:
        return 'Admin';
      case UserRole.superAdmin:
        return 'Super Admin';
    }
  }

  String get description {
    switch (this) {
      case UserRole.member:
        return 'Regular member with view-only access';
      case UserRole.groupAdmin:
        return 'Can manage members in their assigned group';
      case UserRole.admin:
        return 'Can manage all members (cannot assign roles)';
      case UserRole.superAdmin:
        return 'Full access including role management';
    }
  }
}
