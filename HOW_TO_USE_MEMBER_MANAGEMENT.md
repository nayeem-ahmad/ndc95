# How to Use Member Management

## Accessing Member Management

1. **Login as Superadmin** (nayeem.ahmad@gmail.com)
2. Navigate to the **Admin** tab (3rd tab in bottom navigation)
3. Scroll to find the **"Manage Members"** section (green card)
4. Click **"Manage Members"** button

## Adding a New Member

1. In the Manage Members screen, click the **"+ Add Member"** floating button (bottom right)
2. Fill in the required fields (marked with *):
   - Full Name
   - Email
   - Student ID (NDC Roll #)
3. Fill in optional fields as needed
4. Click **"Add Member"** button
5. If email is unique, member is added ✅
6. If email exists, error message appears ❌

## Editing a Member

1. In the member list, find the member you want to edit
2. Click the **blue edit icon** (✏️) on the right side
3. Modify the fields you want to change
4. Click **"Update Member"** button
5. Changes are saved ✅

## Deleting a Member

1. In the member list, find the member you want to delete
2. Click the **red delete icon** (🗑️) on the right side
3. A confirmation dialog appears
4. Click **"Delete"** to confirm (or "Cancel" to abort)
5. Member is removed from the database ✅

## Searching for Members

1. Use the search bar at the top of the Manage Members screen
2. Type any part of a member's name or email
3. Results filter in real-time
4. Click the **X** button to clear the search

## Navigation Flow

```
Home Screen
    ├── Directory Tab (1st tab)
    ├── Profile Tab (2nd tab)
    └── Admin Tab (3rd tab - Superadmin only)
            ├── Admin Tools
            ├── Manage Members ← Click here
            │       ├── Member List
            │       ├── Search Bar
            │       ├── Add Member (+) → Member Form → Add/Save
            │       ├── Edit Member (✏️) → Member Form → Update
            │       └── Delete Member (🗑️) → Confirmation → Delete
            └── Fix Group Fields
```

## Screenshots Description

### Admin Screen
- Shows "Manage Members" section with green card
- Button labeled "Manage Members"
- Description of functionality

### Manage Members Screen
- Search bar at top
- Blue badge showing member count
- List of member cards with:
  - Profile picture/initial
  - Name and email
  - Student ID
  - Edit and Delete buttons
- Floating action button "+ Add Member"

### Member Form Screen (Add)
- Title: "Add New Member"
- Sections with icons:
  - Required Information
  - Personal Information
  - Contact Information
  - Education
  - Professional Information
  - Other Information
- Blue "Add Member" button at bottom

### Member Form Screen (Edit)
- Title: "Edit Member"
- Pre-filled with current member data
- Blue "Update Member" button at bottom

### Delete Confirmation Dialog
- Title: "Delete Member"
- Message: "Are you sure you want to delete [name]?"
- Warning: "This action cannot be undone."
- "Cancel" and "Delete" buttons

## Tips

✅ **Email Validation**: Email must be unique across all members
✅ **Student ID Format**: Use NDC Roll number (e.g., 95301, 956054)
✅ **Group Auto-calculation**: Group is automatically set from 3rd digit of Student ID
✅ **Search Tips**: Search works on both name and email, case-insensitive
✅ **Delete Carefully**: Deletion is permanent and cannot be undone
✅ **Real-time Updates**: Member list updates automatically when changes are made

## Common Issues

### "Email already registered" error
- This email is already used by another member
- Check if the member already exists in the system
- Use a different email address

### Member not appearing in list
- Check if you're in the correct group filter (in Directory tab)
- Try searching for the member by name or email
- Refresh the screen by pulling down

### Group not showing correctly
- Group is automatically calculated from Student ID
- Check if Student ID is entered correctly
- If needed, run "Fix Group Fields" from Admin tab

## Security Notes

🔒 **Superadmin Only**: All member management features are restricted to superadmin
🔒 **Authentication Required**: Must be logged in as nayeem.ahmad@gmail.com
🔒 **No Password Management**: Password reset handled through Firebase Authentication
🔒 **Audit Trail**: All changes are timestamped (createdAt, updatedAt)
