# Role-Based Permission System

## Overview
Implemented a comprehensive role-based permission system with four levels of access: Super Admin, Admin, Group Admin, and Member.

## User Roles

### 1. **Super Admin**
- **Full System Access**
- Can manage all members (add, edit, delete)
- Can assign roles to any member
- Can access all admin tools
- Fixed: nayeem.ahmad@gmail.com (backward compatible)

### 2. **Admin**
- **Full Member Management** (except role assignment)
- Can manage all members (add, edit, delete)
- Cannot assign roles to others
- Can access all admin tools
- Can see all members across all groups

### 3. **Group Admin**
- **Group-Specific Management**
- Can only manage members in their assigned group
- Can add, edit, and delete members within their group
- Cannot assign roles
- Limited to their group's members only
- Automatically filtered by their group

### 4. **Member** (Default)
- **View-Only Access**
- Can view directory
- Can edit own profile only
- No admin panel access
- Default role for all new users

## Role Assignment

### How to Assign Roles (Super Admin Only)

1. Login as Super Admin (nayeem.ahmad@gmail.com)
2. Go to **Admin** tab
3. Click **"Manage All Members"**
4. Find the member you want to promote
5. Click the **purple shield icon** (🛡️) next to their name
6. Select the role from the dialog:
   - Super Admin (red) - Full access
   - Admin (orange) - Manage members
   - Group Admin (green) - Manage group
   - Member (blue) - Regular user
7. Click **"Assign Role"**
8. Role is updated instantly

### Role Assignment Dialog
- Shows current role with icon and description
- Color-coded by role level
- Displays member's group (if applicable)
- Confirmation required before assignment

## Permissions Matrix

| Action | Super Admin | Admin | Group Admin | Member |
|--------|-------------|-------|-------------|--------|
| View Directory | ✅ | ✅ | ✅ | ✅ |
| Edit Own Profile | ✅ | ✅ | ✅ | ✅ |
| Access Admin Panel | ✅ | ✅ | ✅ | ❌ |
| View All Members | ✅ | ✅ | Group Only | ❌ |
| Add New Member | ✅ | ✅ | Group Only | ❌ |
| Edit Any Member | ✅ | ✅ | Group Only | ❌ |
| Delete Any Member | ✅ | ✅ | Group Only | ❌ |
| Assign Roles | ✅ | ❌ | ❌ | ❌ |
| Fix Group Fields | ✅ | ✅ | ✅ | ❌ |

## Technical Implementation

### Database Structure

#### User Document Fields
```dart
{
  'email': 'user@example.com',
  'displayName': 'User Name',
  'role': 'admin',  // 'superAdmin', 'admin', 'groupAdmin', 'member'
  'group': '6',     // Required for groupAdmin
  'roleUpdatedAt': Timestamp,
  // ... other fields
}
```

### Role Service (`lib/services/role_service.dart`)

Key Functions:
- `getUserRole(uid)` - Get user's role from Firestore
- `isSuperAdmin()` - Check if current user is super admin
- `isAdmin()` - Check if admin or higher
- `isGroupAdmin()` - Check if group admin or higher
- `canEditMember(targetUserId)` - Permission check for editing
- `canDeleteMember(targetUserId)` - Permission check for deleting
- `canAssignRoles()` - Check if user can assign roles (super admin only)
- `updateUserRole(userId, newRole)` - Assign role (super admin only)

### Role Model (`lib/models/user_role.dart`)

```dart
enum UserRole {
  member,      // Default
  groupAdmin,  // Group-specific admin
  admin,       // Full admin
  superAdmin,  // System admin
}
```

Extensions:
- `UserRole.value` - Convert to string for database
- `UserRoleExtension.fromString(value)` - Parse from database
- `UserRole.displayName` - Human-readable name
- `UserRole.description` - Role description

### UI Components

#### Role Assignment Dialog (`lib/widgets/role_assignment_dialog.dart`)
- Modal dialog for role selection
- Color-coded role options:
  - Red: Super Admin
  - Orange: Admin
  - Green: Group Admin
  - Blue: Member
- Shows current role and group
- Confirmation button

#### Admin Screen Updates
- Shows current user's role at the top
- Dynamic title based on role:
  - Super Admin: "Manage All Members"
  - Admin: "Manage All Members"
  - Group Admin: "Manage Group X Members"
- Role-specific descriptions

#### Manage Members Screen Updates
- Role badge on member cards
- Color-coded role indicators
- Purple shield icon for role assignment (super admin only)
- Permission-checked edit and delete buttons
- Role filtering in member list

## Screen Access Control

### Home Screen (`lib/screens/home_screen.dart`)
- Dynamically shows/hides Admin tab
- Admin tab visible for: Super Admin, Admin, Group Admin
- Regular members only see: Directory and Profile tabs
- Async role check on init

### Admin Screen (`lib/screens/admin_screen.dart`)
- Shows current user role information
- Dynamic content based on role
- Role-specific descriptions and titles
- Access to management tools

### Manage Members Screen
- Filtered member list based on role:
  - Super Admin/Admin: All members
  - Group Admin: Only their group
  - Member: No access (shouldn't reach this screen)
- Permission-checked actions
- Role assignment button (super admin only)

## Role Assignment Flow

```
Super Admin Login
    ↓
Admin Tab → Manage Members
    ↓
Member List (with role badges)
    ↓
Click Shield Icon (🛡️)
    ↓
Role Assignment Dialog
    ↓
Select New Role:
    ├─ Super Admin (full access)
    ├─ Admin (manage all members)
    ├─ Group Admin (manage group)
    └─ Member (view only)
    ↓
Click "Assign Role"
    ↓
Role Updated in Database
    ↓
Member's Access Updated
```

## Visual Indicators

### Role Badges
- **Super Admin**: Red badge with admin panel icon
- **Admin**: Orange badge with manage accounts icon
- **Group Admin**: Green badge with supervisor icon
- **Member**: No badge (default)

### Color Scheme
- Super Admin: Red (`Colors.red.shade700`)
- Admin: Orange (`Colors.orange.shade700`)
- Group Admin: Green (`Colors.green.shade700`)
- Member: Blue (`Colors.blue.shade700`)

### Icons
- Super Admin: `Icons.admin_panel_settings`
- Admin: `Icons.manage_accounts`
- Group Admin: `Icons.supervisor_account`
- Member: `Icons.person`

## Security Considerations

### Permission Checks
- All admin actions verify permissions before execution
- Role checks use Firestore data (not just local)
- Cannot delete own account
- Cannot edit members outside permission scope

### Role Assignment Security
- Only super admin can assign roles
- Backend validation in RoleService
- Throws exception if unauthorized
- Timestamps all role changes

### Backward Compatibility
- Super admin email check (nayeem.ahmad@gmail.com) still works
- Existing users default to "member" role
- Gradual migration supported

## Group Admin Specifics

### Requirements
- Must have a group assigned (from Student ID)
- Group stored in `group` field
- Cannot access members outside their group

### Permissions
- Add new members to their group only
- Edit members in their group
- Delete members in their group
- View only their group's members

### Group Filtering
- Automatic in Manage Members screen
- Query: `where('group', isEqualTo: userGroup)`
- No manual filter needed

## Testing Checklist

### Role Assignment
- ✅ Super admin can assign any role
- ✅ Admin cannot assign roles (no shield icon)
- ✅ Group admin cannot assign roles
- ✅ Role changes persist after app restart
- ✅ Role badge updates immediately

### Permissions
- ✅ Admin can edit all members
- ✅ Admin can delete all members
- ✅ Group admin can only edit their group
- ✅ Group admin can only delete their group
- ✅ Member cannot access admin panel

### UI Updates
- ✅ Admin tab shows/hides based on role
- ✅ Role badges display correctly
- ✅ Shield icon only for super admin
- ✅ Filtered member list for group admin
- ✅ Role information shows at top of admin screen

## Migration Guide

### Upgrading Existing Users

1. **Automatic Migration**
   - All existing users default to "member" role
   - No database changes needed

2. **Promoting Users**
   - Login as super admin
   - Go to Manage Members
   - Click shield icon on user
   - Assign appropriate role

3. **Group Admin Setup**
   - Ensure user has group field populated
   - Run "Fix Group Fields" if needed
   - Then assign "Group Admin" role

## Common Scenarios

### Scenario 1: Promoting a Member to Admin
1. Super admin logs in
2. Opens Manage Members
3. Finds the member
4. Clicks shield icon
5. Selects "Admin" role
6. Confirms
7. Member now has full member management access

### Scenario 2: Creating Group Admins
1. Ensure member has Student ID and group
2. Super admin assigns "Group Admin" role
3. Member can now manage their group
4. Shows "Manage Group X Members" in admin panel

### Scenario 3: Removing Admin Access
1. Super admin opens Manage Members
2. Finds the admin/group admin
3. Clicks shield icon
4. Selects "Member" role
5. Admin access revoked immediately

## API Reference

### RoleService Methods

```dart
// Get user's role
Future<UserRole> getUserRole(String uid)

// Get user's group
Future<String?> getUserGroup(String uid)

// Check permissions
Future<bool> isSuperAdmin()
Future<bool> isAdmin()
Future<bool> isGroupAdmin()

// Action permissions
Future<bool> canEditMember(String targetUserId)
Future<bool> canDeleteMember(String targetUserId)
Future<bool> canAssignRoles()

// Role management (super admin only)
Future<void> updateUserRole({
  required String userId,
  required UserRole newRole,
})

// Member queries
Stream<QuerySnapshot> getMembersByGroup(String group)
Stream<QuerySnapshot> getAllMembers()
Future<Stream<QuerySnapshot>> getMembersForCurrentUser()
```

## Files Modified/Created

### New Files
1. `lib/models/user_role.dart` - Role enum and extensions
2. `lib/services/role_service.dart` - Permission logic
3. `lib/widgets/role_assignment_dialog.dart` - Role assignment UI

### Modified Files
1. `lib/screens/home_screen.dart` - Dynamic admin tab
2. `lib/screens/admin_screen.dart` - Role info and descriptions
3. `lib/screens/manage_members_screen.dart` - Role badges and assignment

## Future Enhancements

- [ ] Role change audit log
- [ ] Bulk role assignment
- [ ] Custom permissions per role
- [ ] Role templates
- [ ] Time-limited role assignments
- [ ] Role approval workflow
- [ ] Email notifications on role change
- [ ] Activity logs per role
